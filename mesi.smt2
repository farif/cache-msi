(set-option :produce-models true)
(set-logic ALL)

; =====================================
; States
; =====================================

(declare-datatype State ((M) (E) (S) (I)))

; Events: processor actions
(declare-datatype Event ((PrRd0) (PrWr0) (PrRd1) (PrWr1)))

; Current states
(declare-const p0 State)
(declare-const p1 State)

; Next states
(declare-const p0_next State)
(declare-const p1_next State)

; Event
(declare-const action Event)

; =====================================
; Global MESI Transition Relation
; =====================================

(define-fun T ((s0 State) (s1 State)
               (e Event)
               (s0n State) (s1n State)) Bool

  (or

   ; ==============================
   ; Processor 0 READ
   ; ==============================

   (and (= e PrRd0)

        ; If nobody has it
        (ite (= s1 I)
             (and (= s0n E) (= s1n I))
        ; If other has S
        (ite (= s1 S)
             (and (= s0n S) (= s1n S))
        ; If other has E
        (ite (= s1 E)
             (and (= s0n S) (= s1n S))
        ; If other has M
             (and (= s0n S) (= s1n S))
        ))))

   ; ==============================
   ; Processor 0 WRITE
   ; ==============================

   (and (= e PrWr0)

        ; Invalidate other
        (and (= s0n M)
             (= s1n I)))

   ; ==============================
   ; Processor 1 READ
   ; ==============================

   (and (= e PrRd1)

        (ite (= s0 I)
             (and (= s1n E) (= s0n I))
        (ite (= s0 S)
             (and (= s1n S) (= s0n S))
        (ite (= s0 E)
             (and (= s1n S) (= s0n S))
             (and (= s1n S) (= s0n S))
        ))))

   ; ==============================
   ; Processor 1 WRITE
   ; ==============================

   (and (= e PrWr1)

        (and (= s1n M)
             (= s0n I)))
))

; =====================================
; Safety: Full MESI invariant
; =====================================

(define-fun safe ((s0 State) (s1 State)) Bool
  (and

    ; At most one M
    (not (and (= s0 M) (= s1 M)))

    ; M excludes S or E
    (not (and (= s0 M) (or (= s1 S) (= s1 E))))
    (not (and (= s1 M) (or (= s0 S) (= s0 E))))

    ; E must be unique
    (not (and (= s0 E) (not (= s1 I))))
    (not (and (= s1 E) (not (= s0 I))))
  )
)

; =====================================
; Initial State
; =====================================

(assert (= p0 I))
(assert (= p1 I))

; Apply one atomic transition
(assert (T p0 p1 action p0_next p1_next))

; Check safety violation
(assert (not (safe p0_next p1_next)))

(check-sat)
(get-model)