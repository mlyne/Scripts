/*********************************************************************/
/*                                                                   */
/* lt_retrieve.c                                                     */
/*                                                                   */
/* This is a clone of LifeTools(TM) lt_retrieve.  Note that it is    */
/* NOT compatible with the indexes of LifeTools lt_retrieve.  In     */
/* fact, it is only a 'conceptual clone' in that it retrieves        */
/* entries from FASTA format files using an index created by         */
/* lt_create_idx.  It probably has numerous foibles about how picky  */
/* it is with the ID you supply.                                     */
/*                                                                   */
/* Author:  Tim Cutts                                                */
/* Date:    23rd April 1999                                          */
/* (C) Incyte Genetics Ltd.                                          */
/*                                                                   */
/*********************************************************************/

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <limits.h>
#include "lt_index.h"

int usage(void) {
  fprintf(stderr, "\nUsage:  lt_retrieve database fofn\n");
  return 0;
}

FILE *db;
FILE *fofn;
FILE *idx;

int main (int argc, char *argv[])
{

  size_t entry_len;
  int entry_count, n;
  char buf[PATH_MAX];
  char entry_name[ID_LENGTH+1];
  list_ent_t *index, *ptr;
  char *p, *entry_buf;

  if (argc < 2)
    return usage();

  sprintf(buf, "%s.idx", argv[1]);

  if ((idx = fopen(buf, "r")) == NULL) {

    fprintf(stderr,
	    "Can't find index %s: building index...\n",
	    buf);

    sprintf(buf,
	    "lt_create_idx %s",
	    argv[1]); 

    if (system(buf)) {
      perror("Could not run lt_create_idx: ");
      return 1;
    }

    sprintf(buf, "%s.idx", argv[1]);

    if ((idx = fopen(buf, "r")) == NULL) {
      perror("Still can't open index file: ");
      return 1;
    }
  }

  if ((db = fopen(argv[1], "r")) == NULL) {
    perror("Can't open database file: ");
    return 1;
  }

  if (argc <= 2)
    fofn = stdin;
  else {
    if ((fofn = fopen(argv[2], "r")) == NULL) {
      perror("Can't open file of entry names: ");
      return 1;
    }
  }

  if (fread(&entry_len,
	    sizeof(size_t),
	    1,
	    idx) != 1) {
    perror("Error accessing index file: ");
    return 1;
  }

  if (fread(&entry_count,
	    sizeof(int),
	    1,
	    idx) != 1) {
    perror("Error accessing index file: ");
    return 1;
  }

  entry_buf = (char *)malloc(entry_len+20);

  if (entry_buf == NULL) {
    perror("Could not allocate memory for entry buffer: ");
    return 1;
  }

  index = (list_ent_t *)malloc(entry_count*sizeof(list_ent_t));

  if (index == NULL) {
    perror("Could not allocate memory for index: ");
    return 1;
  }

  if ((n = fread(index,
		 sizeof(list_ent_t),
		 entry_count,
		 idx) == 0)) {
    perror("Could not read entire index into memory: ");
    return 1;
  }

  fclose(idx);

  while (fgets(entry_name, ID_LENGTH, fofn)) {
    p = (char *)strchr(entry_name, '\n');
    *p = '\0';
    mystrncpy(entry_name, entry_name, ID_LENGTH);

    ptr = bsearch(entry_name,
		  index,
		  entry_count,
		  sizeof(list_ent_t),
		  ent_compare);

    if ( ptr == NULL ) {
      fprintf(stderr, "Could not find %s in %s\n",
	      entry_name,
	      argv[1]);
    } else {
      fseek(db, ptr->start, SEEK_SET);
      entry_len = ptr->stop - ptr->start;
      fread(entry_buf, sizeof(char), entry_len, db);
      entry_buf[entry_len] = '\0';
      printf("%s", entry_buf);
    }
  }

  if (argc > 2)
    fclose(fofn);

  fclose(db);

  return 0;
}
