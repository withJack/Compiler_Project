/****************************************************/
/* File: symtab.h                                   */
/* Symbol table interface for the TINY compiler     */
/* (allows only one symbol table)                   */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/****************************************************/

#ifndef _SYMTAB_H_
#define _SYMTAB_H_

#include "globals.h"
#define SIZE 211

typedef struct LineListRec
{
	int lineno;
	struct LineListRec * next;
} * LineList;

typedef struct BucketListRec
{
	char * name;
	ExpType type;
	LineList lines;
	TreeNode *treeNode;
	int memloc;
	struct BucketListRec * next;
} * BucketList;

typedef struct ScopeListRec
{
	char * name;
	int loc;
	int startLineNo;
	int endLineNo;
	BucketList bucket[SIZE];
	struct ScopeListRec * parent;
} * ScopeList;

void initScopeStack();
ScopeList ss_top();
void ss_push(char *scope, int startLineNo);
ScopeList ss_pop();

void ss_bucket_add(char *name, ExpType type, int lineno, TreeNode *t);
void ss_line_add(char *name, int lineno, TreeNode *tn);
BucketList ss_lookup(char *name);
BucketList ss_lookup_excluding_parent(char *name);

void st_insert();
BucketList st_lookup(char *scope, char *name);

void printSymTab(FILE * listing);
void printScopeStack(FILE * listing);
#endif
