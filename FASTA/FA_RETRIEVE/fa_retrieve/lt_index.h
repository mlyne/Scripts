/*********************************************************************/
/*                                                                   */
/* lt_index.h                                                        */
/*                                                                   */
/* Types and other definitions                                       */
/*                                                                   */
/* Author:  Tim Cutts                                                */
/* Date:    23rd April 1999                                          */
/* (C) Incyte Genetics Ltd.                                          */
/*                                                                   */
/*********************************************************************/

#include <sys/types.h>

#define BUFSZ 8192

#ifndef ID_LENGTH
#define ID_LENGTH 40
#endif

extern void mystrncpy(char *, char*, int);
extern int ent_compare(const void *, const void *);

struct index_ent;

typedef struct index_ent index_ent_t;
typedef struct list_ent list_ent_t;

struct list_ent {
  char id[ID_LENGTH];
  off_t start;
  off_t stop;
};

struct index_ent {
  struct list_ent t;
  index_ent_t *next;
};
