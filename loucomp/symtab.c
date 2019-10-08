/****************************************************/
/* File: symtab.c                                   */
/* Symbol table implementation for the TINY compiler*/
/* (allows only one symbol table)                   */
/* Symbol table is implemented as a chained         */
/* hash table                                       */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/****************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtab.h"

/* SIZE is the size of the hash table */
#define SIZE 211

/* SHIFT is the power of two used as multiplier
   in hash function  */
#define SHIFT 4

/* the hash function */
static int hash ( char * key )
{ int temp = 0;
  int i = 0;
  while (key[i] != '\0')
  { temp = ((temp << SHIFT) + key[i]) % SIZE;
    ++i;
  }
  return temp;
}

// global symbol table
static ScopeList symbolTable;
// global scope stack(table)
static ScopeList scopeStack;


BucketList makeBucketList(char *name, ExpType type, int lineno, int loc, TreeNode *t) {
  BucketList l = (BucketList)malloc(sizeof(struct BucketListRec));
  l->name = name;
  l->type = type;
  l->lines = (LineList) malloc(sizeof(struct LineListRec));
  l->lines->lineno = lineno;
  l->lines->next = NULL;
  l->memloc = loc;
  l->next = NULL;
  l->treeNode = t;
  return l;
}

ScopeList makeScopeList(char *scope, int loc, int startLineNo, int endLineNo) {
  ScopeList l = (ScopeList)malloc(sizeof(struct ScopeListRec));
  l->name = scope;
  l->loc = loc;
  l->startLineNo = startLineNo;
  l->endLineNo = endLineNo;
  l->parent = NULL;
  return l;
}

void initScopeStack() {
  ss_push("global", 0);

  TreeNode *func;
  TreeNode *typeSpec;
  TreeNode *param;
  TreeNode *compStmt;

  // input()
  func = newDeclNode(FuncK);
  func->type = Integer;
  typeSpec = newTypeNode(TypeSpecK);
  typeSpec->attr.type = INT;
  
  
  compStmt = newStmtNode(CompK);
  compStmt->child[0] = NULL;      // no local var
  compStmt->child[1] = NULL;      // no stmt

  func->lineno = 0;
  func->attr.name = "input";
  func->child[0] = typeSpec;
  func->child[1] = NULL;          // no param
  func->child[2] = compStmt;
  func->scopename = "global";

  ss_bucket_add("input", Integer, 0, func);

  // output()
  func = newDeclNode(FuncK);
  func->type = Void;
  typeSpec = newTypeNode(TypeSpecK);
  typeSpec->attr.type = VOID;
  
  param = newParamNode(SingleParamK);
  param->attr.name = "arg";
  param->type = Integer;
  param->child[0] = newTypeNode(TypeSpecK);
  param->child[0]->attr.type = INT;

  compStmt = newStmtNode(CompK);
  compStmt->child[0] = NULL;      // no local var
  compStmt->child[1] = NULL;      // no stmt

  func->lineno = 0;
  func->attr.name = "output";
  func->child[0] = typeSpec;
  func->child[1] = param;
  func->child[2] = compStmt;
  func->scopename = "global";

  ss_bucket_add("output", Void, 0, func);

  scopeStack->loc = 2;
}

ScopeList ss_top() {
  return scopeStack;
}

void ss_push(char *scope, int startLineNo) {
  ScopeList s = (ScopeList)malloc(sizeof(struct ScopeListRec));
  s->name = scope;
  s->loc = 0;
  s->startLineNo = startLineNo;
  s->endLineNo = 0;

  s->parent = scopeStack;
  scopeStack = s;
}

ScopeList ss_pop() {
  ScopeList s = scopeStack;
  scopeStack = scopeStack->parent;
  return s;
}

void ss_bucket_add(char *name, ExpType type, int lineno, TreeNode *t) {
  int h = hash(name);
  int loc = scopeStack->loc;
  BucketList l = makeBucketList(name, type, lineno, loc, t);

  scopeStack->loc++;

  l->next = scopeStack->bucket[h];
  scopeStack->bucket[h] = l;
}

void ss_line_add(char *name, int lineno, TreeNode *tn) {
  int h = hash(name);

  ScopeList s = scopeStack;
  while(s != NULL) {
    BucketList l = s->bucket[h];
 
    while(l != NULL && strcmp(l->name,name) != 0) 
      l = l->next;

    if(l == NULL) s = s->parent;
    else {
      LineList t = l->lines;
      while(t->next != NULL) t = t->next;
      t->next = (LineList)malloc(sizeof(struct LineListRec));
      t->next->lineno = lineno;
      t->next->next = NULL;
      tn->type = l->type;
      tn->scopename = l->treeNode->scopename;
      break;
    }
  }
}

// Expk
BucketList ss_lookup(char *name) {
  ScopeList s = scopeStack;

  int h = hash(name);
  while(s != NULL) {
    BucketList l = s->bucket[h];
    while(l != NULL && strcmp(name,l->name) != 0) 
      l = l->next;
    if(l == NULL) s = s->parent;
    else return l;
  }
  return NULL;
}

// DeclK, ParamK
BucketList ss_lookup_excluding_parent(char *name) {
  int h = hash(name);
  BucketList l = scopeStack->bucket[h];

  while(l != NULL && strcmp(name,l->name) != 0)
    l = l->next;
  return l;
}

void st_insert() {
  ScopeList s = ss_pop();
  s->parent = symbolTable;
  symbolTable = s;
}


BucketList st_lookup(char *scope, char *name) {
  // printSymTab(listing);
  int h = hash(name);
  ScopeList s = symbolTable;
  BucketList l = NULL;
  while(s != NULL && strcmp(scope, s->name) != 0) 
    s = s->parent;

  while(s != NULL) {
    BucketList l = s->bucket[h];
    while(l != NULL && strcmp(name, l->name) != 0) 
      l = l->next;

    if(l == NULL) s = s->parent;
    else return l; 
  }
}

/* Procedure printSymTab prints a formatted 
 * listing of the symbol table contents 
 * to the listing file
 */

void printSymTab(FILE * listing)
{ int i;
  fprintf(listing, "SymbolTable : \n");
  fprintf(listing,"    Scope      Variable Name      Type         Location   Line Numbers\n");
  fprintf(listing,"-------------  -------------  --------------  ----------  ------------\n");
  ScopeList s = symbolTable;
  while(s != NULL) {
    for(i=0;i<SIZE;++i) {
      if(s->bucket[i] != NULL) {
        BucketList l = s->bucket[i];
        while(l != NULL) {
          LineList t = l->lines;
          fprintf(listing," %-14s",s->name);
          fprintf(listing," %-14s",l->name);
          switch(l->type) {
            case Void:
              fprintf(listing," %-16s","Void");
              break;
            case Integer:
              fprintf(listing," %-16s","Integer");
              break;
            case IntegerArray:
              fprintf(listing, " %-16s","IntegerArray");
              break;
            default:
              break;
          }
          fprintf(listing,"%-8d  ",l->memloc);
          while(t != NULL) {
            fprintf(listing,"%4d ",t->lineno);
            t = t->next;
          }
          fprintf(listing,"\n");
          l = l->next;
        }
      }
    }
    s = s->parent;
	  fprintf(listing, "----------------------------------------------------------------------\n");
  }
} /* printSymTab */
