/*********************************************************************/
/*                                                                   */
/* lt_createidx.c                                                    */
/*                                                                   */
/* This is a clone of LifeTools(TM) lt_create_idx.  Note that it is  */
/* NOT compatible with the indexes of LifeTools lt_retrieve.  In     */
/* fact, it is only a 'conceptual clone' in that it indexes FASTA    */
/* format files for fetching with its associated lt_retrieve         */
/* program.  It probably has numerous foibles about how picky        */
/* it is with the ID you supply.                                     */
/*                                                                   */
/* Author:  Tim Cutts                                                */
/* Date:    23rd April 1999                                          */
/* (C) Incyte Genetics Ltd.                                          */
/*                                                                   */
/*********************************************************************/

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/types.h>
#include "lt_index.h"

/* Forward declarations */

int index_database(char *);

/* Global variables */

FILE *db;

int main (int argc, char *argv[])
{

  int r;

  if (argc != 2)
    {
      fprintf(stderr, "Which database?\n");
      return 1;
    }

  if ((db=fopen(argv[1], "r")) == NULL)
    {
      perror("Could not open database for indexing: ");
      return 1;
    }

  r = index_database(argv[1]);

  return 0;
}


/*********************************************************************/

int index_database(char *name)
{

  char *buf, *p;
  off_t fptr = 0;
  size_t largest = 0;
  int count = 0;
  int i;

  index_ent_t *first = NULL;
  index_ent_t *new = NULL;
  index_ent_t *current;
  list_ent_t *list;

  buf=(char *)malloc(BUFSZ+1);

  while (fgets(buf, BUFSZ, db)) {
    if (buf[0] == '>') {
      count++;
      if (new) {
	new->t.stop = fptr;
	if (new->t.stop - new->t.start > largest)
	  largest = new->t.stop - new->t.start;
	if ((count & 0x3FF) == 0)
	  {
	    fprintf(stderr, "Processed %d entries\n", count);
	  }
      }
      new = (index_ent_t *)malloc(sizeof(index_ent_t));
      new->next = NULL;
      p = (char *)strchr(buf, '\n');
      *p = '\0';
      mystrncpy(new->t.id, &buf[1], ID_LENGTH);
      new->t.start = fptr;

      if (first == NULL) {
	current = first = new;
      } else {
	current->next = new;
	current = new;
      }
    }
    
    fptr = ftell(db);

  }

  new->t.stop = ftell(db);

  fclose(db);

  /* Now to write out our index file */
  
  sprintf(buf, "%s.idx", name);
  db = fopen(buf, "w");

  if (db == NULL) {
    perror("Could not open index file for writing: ");
    return 1;
  }

  /* Write the largest sequence length, and count of sequences */

  fwrite(&largest,
	 sizeof(size_t),
	 1,
	 db);

  fwrite(&count,
	 sizeof(int),
	 1,
	 db);

  /* Now sort the entries */

  list = (list_ent_t *)malloc(count*sizeof(list_ent_t));

  if (list == NULL) {
    perror ("Out of memory: ");
    return 1;
  }

  i = 0;
  current = first;

  do {
    list[i] = current->t;
    current = current->next;
    i++;
  } while (current->next != NULL);
  
  qsort(list, count, sizeof(list_ent_t), ent_compare);

  /* Now write out all the offsets */

  fwrite(list, sizeof(list_ent_t), count, db);

  fclose(db);

  /* Print a report */

  fprintf(stderr,
	  "Entries:\t%d\nLongest:\t%d letters\n",
	  count,
	  largest);

  return 0;
}
