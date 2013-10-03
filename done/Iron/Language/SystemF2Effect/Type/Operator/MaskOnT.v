
Require Import Iron.Language.SystemF2Effect.Type.Relation.KindT.
Require Import Iron.Language.SystemF2Effect.Type.Relation.SubsT.
Require Import Iron.Language.SystemF2Effect.Type.Relation.SubsTs.
Require Import Iron.Language.SystemF2Effect.Type.Operator.FreeTT.
Require Import Iron.Language.SystemF2Effect.Type.Operator.LiftTT.
Require Import Iron.Language.SystemF2Effect.Type.Operator.SubstTT.
Require Import Iron.Language.SystemF2Effect.Type.Exp.
Require Import Coq.Bool.Bool.


(********************************************************************)
(* Mask effects on the given region, 
   replacing with the bottom effect. *)
Fixpoint maskOnT (p : ty -> bool) (e : ty) : ty
 := match e with
    |  TSum t1 t2  => TSum (maskOnT p t1) (maskOnT p t2)
    |  TCon1 tc t1 => if p e then TBot KEffect else e
    | _            => e
    end.
Arguments maskOnT p e : simpl nomatch.


Definition maskOnVarT    (n : nat) (e : ty) : ty
 := maskOnT (isEffectOnVar n) e.

Definition maskOnCapT    (n : nat) (e : ty) : ty
 := maskOnT (isEffectOnCap n) e.


(********************************************************************)
(* Masking some effects in a type preserves its kind. *)
Lemma maskOnT_kind
 :  forall ke sp t k p
 ,  KindT  ke sp t k 
 -> KindT  ke sp (maskOnT p t) k.
Proof.
 intros. gen ke sp k.
 induction t; intros; inverts_kind; simpl; eauto 4.

 - Case "TCon1".
   unfold maskOnT. 
   split_if.
   + destruct t; snorm.
      inverts H4. auto.
      inverts H4. auto.
      inverts H4. auto.
   + destruct t; snorm;
      inverts H4; eapply KiCon1; simpl; eauto.

 - Case "TCon2".
   destruct tc.
   snorm. inverts H2.
   spec IHt1 H5.
   spec IHt2 H7.
   eapply KiCon2. 
    destruct t1. snorm.
    eauto. eauto.
Qed.
Hint Resolve maskOnT_kind.


(* Masking effects on variables in a type preserves its kind. *)
Lemma maskOnVarT_kind
 :  forall ke sp t k n
 ,  KindT  ke sp t k
 -> KindT  ke sp (maskOnVarT n t) k.
Proof.
 intros. 
 unfold maskOnVarT. 
 eapply maskOnT_kind; auto.
Qed.
Hint Resolve maskOnVarT_kind.


(* Masking effects on capabilities in a type preserves its kind. *)
Lemma maskOnCapT_kind
 :  forall ke sp t k n
 ,  KindT  ke sp t k
 -> KindT  ke sp (maskOnCapT n t) k.
Proof.
 intros.
 unfold maskOnVarT.
 eapply maskOnT_kind; auto.
Qed.
Hint Resolve maskOnCapT_kind.


(********************************************************************)
Lemma maskOn_equivT
 :  forall ke sp t1 t2 k p
 ,  EquivT ke sp t1 t2 k
 -> EquivT ke sp (maskOnT p t1) (maskOnT p t2) k.
Proof.
 intros.
 induction H;
  try (solve [snorm; eauto 2]).
Qed. 
Hint Resolve maskOn_equivT.


Lemma maskOnT_subsT
 :  forall ke sp t1 t2 k p
 ,  SubsT  ke sp t1 t2 k
 -> SubsT  ke sp (maskOnT p t1) (maskOnT p t2) k.
Proof.
 intros.
 induction H;
  try (solve [snorm; eauto 2]).
Qed.
Hint Resolve maskOnT_subsT.


(********************************************************************)
Lemma maskOnT_idemp
 : forall p t
 , maskOnT p (maskOnT p t) = maskOnT p t.
Proof.
 intros.
 induction t; intros; snorm.
 - repeat rewritess. auto.
 - unfold maskOnT at 2. 
   split_if.
   + unfold maskOnT at 2.
     rewrite <- HeqH. snorm.
   + auto.
Qed.
Hint Resolve maskOnT_idemp.


(********************************************************************)
(* If a given region variable is not free in a type, 
   then masking effects on that variable is identity. *)
Lemma maskOnVarT_freeTT_id
 :  forall d t 
 ,  freeTT d t = false 
 -> maskOnVarT d t = t.
Proof.
 intros. gen d.
 induction t; intros; 
  try (solve [unfold maskOnVarT; snorm]).

 - Case "TSum".
   unfold maskOnVarT in *. 
   snorm.
   repeat rewritess; auto.

 - Case "TCon1".
   unfold maskOnVarT in *.
   snorm.
   unfold maskOnT.
   split_if; auto.
   + destruct t0; try (solve [snorm; rip; nope]).
Qed.


(********************************************************************)
(* Push masking through lifting. *)
Lemma maskOnVarT_liftTT
 :  forall r d e
 ,  maskOnVarT r (liftTT 1 (1 + (r + d)) e) 
 =  liftTT 1 (1 + (r + d)) (maskOnVarT r e).
Proof.
 intros. gen r d.
 induction e; intros; 
  try (solve [simpl; burn]);
  try (solve [simpl; f_equal; rewritess; auto]).

 - Case "TSum".
   simpl.
   unfold maskOnVarT in *.
   simpl. f_equal; eauto.

 - Case "TCon1".
   unfold maskOnVarT in *.
   simpl.
   unfold maskOnT. 
   split_if. 
   + split_if.
     * simpl. auto.
     * snorm.
       inverts HeqH0.
        congruence.
        eapply liftTT_isTVar_true in H0. 
         congruence. omega.
   + split_if.
     * snorm.
       inverts HeqH.
        congruence.
        apply isTVar_form in H0. subst.
        rewrite liftTT_TVar_above in H1.
        simpl in H1.
        rewrite <- beq_nat_refl in H1. 
         nope. omega.
     * simpl. auto.
Qed.
Hint Resolve maskOnVarT_liftTT.


(********************************************************************)
(* Push masking through substitution. *)
Lemma maskOnVarT_substTT
 :  forall d d' t1 t2
 ,  freeTT d t2 = false
 -> maskOnVarT d (substTT (1 + d' + d) t2 t1)
 =  substTT (1 + d' + d) (maskOnVarT d t2) (maskOnVarT d t1).
Proof.
 intros. gen d t2.
 induction t1; intros; 
   try (solve [simpl; burn]).

 - Case "TForall".
   unfold maskOnVarT in *.
   snorm.
   f_equal. f_equal.
   lets D: maskOnVarT_freeTT_id. 
   unfold  maskOnVarT in *.
   rewritess; auto.
 
 - Case "TApp".
   unfold maskOnVarT in *.
   snorm.
   f_equal. 
   + f_equal. 
     lets D: maskOnVarT_freeTT_id.
     unfold  maskOnVarT in *.
     rewritess; auto.
   + f_equal.
     lets D: maskOnVarT_freeTT_id.
     unfold  maskOnVarT in *.
     rewritess; auto.

 - Case "TSum".
   unfold maskOnVarT in *.
   snorm.
   f_equal.
   + rewritess; auto.
   + rewritess; auto.

 - Case "TCon1".
   unfold maskOnVarT.
   unfold maskOnT; split_if; fold maskOnT.
   + snorm.
     apply isTVar_form in H1. subst. 
     spec IHt1 d t2. rip.
     unfold maskOnT.
     snorm; try omega.
     * inverts HeqH1.
        congruence. 
        snorm. omega.

   + simpl. 
     unfold maskOnT; split_if; fold maskOnT.

     * unfold isEffectOnVar in HeqH0.
       unfold isEffectOnVar in HeqH1.
       snorm.
       inverts HeqH0. 
        congruence.
        apply isTVar_form in H1.
        destruct t1; snorm; try congruence.
         subst. snorm. nope.
         inverts H1. omega.

     * repeat f_equal.
       lets D: maskOnVarT_freeTT_id. 
       unfold maskOnVarT in *.
       erewrite D; auto.
  
 - Case "TCon2".
   unfold maskOnVarT in *.
   snorm. 
   f_equal.
   + f_equal.
     lets D: maskOnVarT_freeTT_id. 
     unfold  maskOnVarT in *.
     rewritess; auto.
   + f_equal.
     lets D: maskOnVarT_freeTT_id. 
     unfold  maskOnVarT in *.
     rewritess; auto.
Qed.


(********************************************************************)
Lemma maskOnVar_effect_remains
 :  forall t tc p n e
 ,  t = TCon1 tc (TCap (TyCapRegion p))
 -> In t (flattenT e)
 -> In t (flattenT (maskOnVarT n e)).
Proof.
 intros.
 induction e; snorm.

 - Case "TSum".
   apply in_app_split in H0.
   inverts H0; snorm.

 - Case "TCon1".
   + inverts H0.
     inverts H1.
     snorm.
     unfold maskOnVarT.
     unfold maskOnT.
     split_if.
     * snorm. nope.
     * snorm.
     * nope.
Qed.