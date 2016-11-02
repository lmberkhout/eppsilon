pro slurm_ps_job
  ;; wrapper for ps_wrapper to take in shell parameters

;  PROFILER, /RESET
;  RESOLVE_ROUTINE, 'ps_wrapper', /QUIET
;  RESOLVE_ALL, /CONTINUE_ON_ERROR, /QUIET

  compile_opt strictarr
  args = Command_Line_Args(count=nargs)
  folder_name=args[0]
  obs_range=args[1]
  ;if (nargs eq 3) then n_obs=args[2]
  print,'folder_name = '+folder_name
  print,'obs_range = '+obs_range

  ;;;;;; Which plots?:
  plot_stdset=0
  plot_slices=0
;  slice_type='raw'
;  uvf_plot_type='abs'	; These two only used if plot_slices=1
  plot_1to2d=0
  plot_2d_masked=0
  plot_kpar_power=1
  plot_kperp_power=1
  plot_k0_power =0
  plot_noise_1d = 0
  plot_sim_noise = 0
  plot_binning_hist= 0   ;for debugging

  ;;;;;; 2D plotting options
  plot_wedge_line=1
  kperp_linear_axis=0
  kpar_linear_axis=0
;  kperp_plot_range=
;  kperp_lambda_plot_range=
;  kpar_plot_range=
  baseline_axis=1
  delay_axis=1
  cable_length_axis=0

  ;;;;;; 1D plotting options
  set_krange_1dave=1
;  range_1d=
  plot_1d_delta=1
  plot_1d_error_bars=1
  plot_1d_nsigma=1
  plot_eor_1d=1
  plot_flat_1d=0
  no_text_1d=0

  png=1

  extra = var_bundle()


  ps_wrapper,folder_name,obs_range,/exact_obsnames,loc_name='oscar', _Extra=extra


;  if (nargs eq 3) then begin
;     n_obs=args[2]
;     ps_wrapper,folder_name,obs_range,n_obs=n_obs,/plot_kpar_power,/plot_kperp_power,/png,/plot_k0_power,/plot_eor_1d,/exact_obsnames,loc_name='oscar'
;  endif else begin
;     ps_wrapper,folder_name,obs_range,/plot_kpar_power,/plot_kperp_power,/png,/plot_k0_power,/plot_eor_1d,/exact_obsnames,loc_name='oscar'
;  endelse
 
end
