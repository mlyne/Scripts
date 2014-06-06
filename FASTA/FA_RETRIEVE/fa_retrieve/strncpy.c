/*********************************************************************/
/*                                                                   */
/* strncpy.c                                                         */
/*                                                                   */
/* Miscellaneous functions used by both lt_retrieve and              */
/* lt_create_idx                                                     */
/*                                                                   */
/* Author:  Tim Cutts                                                */
/* Date:    23rd April 1999                                          */
/* (C) Incyte Genetics Ltd.                                          */
/*                                                                   */
/*********************************************************************/

#include <string.h>
#include <ctype.h>
#include "lt_index.h"

void mystrncpy(char *dest, char *src, int len)
{
  int n = 0;
  while ((n < len) && (src[n] != '\0')) {
    dest[n] = toupper(src[n]);
    n++;
  }
  dest[n] = '\0';
}

/*********************************************************************/

int ent_compare(const void *s, const void *t)
{
  return strcmp(((list_ent_t *)s)->id,
		((list_ent_t *)t)->id);
}
