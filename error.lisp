#| Should give error - use before initialization |#
(setq b a)
(+ a b)

#| Should give experimental feature warning |#
(setq a "Hello")
(print a)

#| Should give warning about arithmetic operation on an integer and string and print 7|#
(setq b (+ a 7))
(print b)

#| Should give warning about arithmetic operation on an integer and string and print 5|#
(setq b (+ 5 a))
(print b)

#| Should give warning about arithmetic operation on string and string and print 0 |#
(setq b (+ a a))
(print b)

(setq b (+ 7 7))
(print b)
