-- mode describing animated sprite behavior when animation is over
anim_loop_modes = {
  freeze_first = 1, -- go back to 1st frame and stop playing
  freeze_last  = 2, -- keep last frame and stop playing
  clear        = 3, -- stop showing sprite completely
  loop         = 4, -- go back to 1st frame and continue playing
}
