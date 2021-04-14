(setq a (+ 5 3))
(setq b (* 5 3))
(setq c (- 5 3))
(setq d (and T F))
(setq e 100)

(case a
    (1 (setq e 5))
    (2 (setq e 7))
    (8 (if (<= d 0)
            (case b
                (14 (setq e 10))
                (15  (case c
                        (2 (setq e 15))
                        (3 (setq e 17))
                    )
                )
            )
        )
    )
)

(print "Value of e is")
(print e)
