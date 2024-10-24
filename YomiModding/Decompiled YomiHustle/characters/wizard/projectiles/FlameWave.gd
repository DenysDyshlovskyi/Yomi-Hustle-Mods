extends BaseProjectile








func disable():
	.disable()
	if creator:
		creator.flame_wave_cooldown = creator.FLAME_WAVE_COOLDOWN
