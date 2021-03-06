pro ps_ratio_plots, folder_names, obs_info, cube_types, pols, ps_foldernames=ps_foldernames, $
    all_pol_diff_ratio = all_pol_diff_ratio, $
    uvf_options0 = uvf_options0, uvf_options1 = uvf_options1, ps_options = ps_options, $
    plot_options = plot_options, plot_2d_options = plot_2d_options, $
    plot_slices = plot_slices, slice_type = slice_type, $
    freq_ch_range = freq_ch_range, plot_filebase = plot_filebase, save_path=save_path, $
    diff_ratio = diff_ratio, diff_range = diff_range, diff_min_abs = diff_min_abs, $
    invert_colorbar = invert_colorbar, quiet = quiet, window_num = window_num

  fadd_2dbin = ''
  ;;if keyword_set(fill_holes) then fadd_2dbin = fadd_2dbin + '_nohole'
  if keyword_set(no_kzero) then fadd_2dbin = fadd_2dbin + '_nok0'
  if keyword_set(log_kpar) then fadd_2dbin = fadd_2dbin + '_logkpar'
  if keyword_set(log_kperp) then fadd_2dbin = fadd_2dbin + '_logkperp'

  compare_plot_prep, folder_names, obs_info, cube_types, pols, 'ratio', compare_files, $
    ps_foldernames=ps_foldernames, $
    uvf_options0 = uvf_options0, uvf_options1 = uvf_options1, ps_options = ps_options, $
    plot_options = plot_options, plot_2d_options = plot_2d_options, $
    plot_slices = plot_slices, slice_type = slice_type, fadd_2dbin = fadd_2dbin, $
    freq_ch_range = freq_ch_range, $
    plot_filebase = plot_filebase, save_path = save_path, savefilebase = savefilebase, $
    axis_type_1d = axis_type_1d, full_compare = all_pol_diff_ratio

  test_save1 = file_valid(compare_files.input_savefile1)
  test_save2 = file_valid(compare_files.input_savefile2)

  if min(test_save1) eq 0 then begin
    message, '2D savefile not found: ' + $
      strjoin(compare_files.input_savefile1[where(test_save1 eq 0)], ', ')
  endif
  if min(test_save2) eq 0 then begin
    message, '2D savefile not found: ' + $
      strjoin(compare_files.input_savefile2[where(test_save2 eq 0)], ', ')
    endif

  for slice_i=0, compare_files.n_slices-1 do begin
    if keyword_set(diff_ratio) or keyword_set(all_pol_diff_ratio) then begin

      for i=0, compare_files.n_sets/2-1 do begin

        if keyword_set(plot_slices) then begin
          slice_axis = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i], 'slice_axis')
          slice_axis2 = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i+1], 'slice_axis')
          slice_axis3 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i], 'slice_axis')
          slice_axis4 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i+1], 'slice_axis')
          if slice_axis ne slice_axis2 or slice_axis ne slice_axis3 or slice_axis ne slice_axis4 then $
            message, 'slice_axis does not match in savefiles'

          slice_inds = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i], 'slice_inds')
          slice_inds2 = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i+1], 'slice_inds')
          slice_inds3 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i], 'slice_inds')
          slice_inds4 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i+1], 'slice_inds')
          if slice_inds ne slice_inds2 or slice_inds ne slice_inds3 or slice_inds ne slice_inds4 then $
            message, 'slice_inds does not match in savefiles'

          xarr = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i], 'xarr')
          xarr2 = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i+1], 'xarr')
          xarr3 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i], 'xarr')
          xarr4 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i+1], 'xarr')
          if n_elements(xarr) ne n_elements(xarr2) or max(abs(xarr - xarr2)) gt 1.05e-3 or $
            n_elements(xarr) ne n_elements(xarr3) or max(abs(xarr - xarr3)) gt 1.05e-3 or $
            n_elements(xarr) ne n_elements(xarr4) or max(abs(xarr - xarr4)) gt 1.05e-3 then $
            message, 'xarr does not match in savefiles'
          yarr = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i], 'yarr')
          yarr2 = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i+1], 'yarr')
          yarr3 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i], 'yarr')
          yarr4 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i+1], 'yarr')
          if n_elements(yarr) ne n_elements(yarr2) or max(abs(yarr - yarr2)) gt 1.05e-3 or $
            n_elements(yarr) ne n_elements(yarr3) or max(abs(yarr - yarr3)) gt 1.05e-3 or $
            n_elements(yarr) ne n_elements(yarr4) or max(abs(yarr - yarr4)) gt 1.05e-3 then $
            message, 'yarr does not match in savefiles'

        endif else begin
          kperp_edges = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i], 'kperp_edges')
          kperp_edges2 = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i+1], 'kperp_edges')
          kperp_edges3 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i], 'kperp_edges')
          kperp_edges4 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i+1], 'kperp_edges')
          if n_elements(kperp_edges) ne n_elements(kperp_edges2) or max(abs(kperp_edges - kperp_edges2)) gt 1.05e-3 or $
            n_elements(kperp_edges) ne n_elements(kperp_edges3) or max(abs(kperp_edges - kperp_edges3)) gt 1.05e-3 or $
            n_elements(kperp_edges) ne n_elements(kperp_edges4) or max(abs(kperp_edges - kperp_edges4)) gt 1.05e-3 then $
            message, 'kperp_edges does not match in savefiles'
          kpar_edges = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i], 'kpar_edges')
          kpar_edges2 = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i+1], 'kpar_edges')
          kpar_edges3 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i], 'kpar_edges')
          kpar_edges4 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i+1], 'kpar_edges')
          if n_elements(kpar_edges) ne n_elements(kpar_edges2) or max(abs(kpar_edges - kpar_edges2)) gt 1.05e-3 or $
            n_elements(kpar_edges) ne n_elements(kpar_edges3) or max(abs(kpar_edges - kpar_edges3)) gt 1.05e-3 or $
            n_elements(kpar_edges) ne n_elements(kpar_edges4) or max(abs(kpar_edges - kpar_edges4)) gt 1.05e-3 then $
            message, 'kpar_edges does not match in savefiles'

          kperp_bin = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i], 'kperp_bin')
          kperp_bin2 = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i+1], 'kperp_bin')
          kperp_bin3 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i], 'kperp_bin')
          kperp_bin4 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i+1], 'kperp_bin')
          if abs(kperp_bin - kperp_bin2) gt 1.05e-3 or abs(kperp_bin - kperp_bin3) gt 1.05e-3 or $
            abs(kperp_bin - kperp_bin4) gt 1.05e-3 then $
            message, 'kperp_bin does not match in savefiles'
          kpar_bin = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i], 'kpar_bin')
          kpar_bin2 = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i+1], 'kpar_bin')
          kpar_bin3 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i], 'kpar_bin')
          kpar_bin4 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i+1], 'kpar_bin')
          if abs(kpar_bin - kpar_bin2) gt 1.05e-3 or abs(kpar_bin - kpar_bin3) gt 1.05e-3 or $
            abs(kpar_bin - kpar_bin4) gt 1.05e-3 then $
            message, 'kpar_edges does not match in savefiles'
        endelse

        kperp_lambda_conv = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i], 'kperp_lambda_conv')
        kperp_lambda_conv2 = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i+1], 'kperp_lambda_conv')
        kperp_lambda_conv3 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i], 'kperp_lambda_conv')
        kperp_lambda_conv4 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i+1], 'kperp_lambda_conv')
        if abs(kperp_lambda_conv - kperp_lambda_conv2)/kperp_lambda_conv gt 1.05e-3 or $
          abs(kperp_lambda_conv - kperp_lambda_conv3)/kperp_lambda_conv gt 1.05e-3 or $
          abs(kperp_lambda_conv - kperp_lambda_conv4)/kperp_lambda_conv gt 1.05e-3 then $
          message, 'kperp_lambda_conv do not match in savefiles'
        delay_params = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i], 'delay_params')
        delay_params2 = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i+1], 'delay_params')
        delay_params3 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i], 'delay_params')
        delay_params4 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i+1], 'delay_params')
        if max(abs(delay_params - delay_params2)) gt 1.05e-3 or $
          max(abs(delay_params - delay_params3)) gt 1.05e-3 or $
          max(abs(delay_params - delay_params4)) gt 1.05e-3 then $
          message, 'delay_params do not match in savefiles'
        hubble_param = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i], 'hubble_param')
        hubble_param2 = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i+1], 'hubble_param')
        hubble_param3 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i], 'hubble_param')
        hubble_param4 = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i+1], 'hubble_param')
        if abs(hubble_param - hubble_param2) ne 0  or  abs(hubble_param - hubble_param4) ne 0 or $
          abs(hubble_param - hubble_param4) ne 0 then message, 'hubble_param do not match in savefiles'

        power1a = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i], 'power')
        power2a = getvar_savefile(compare_files.input_savefile1[slice_i, 2*i+1], 'power')

        power_ratio1 = power1a / power2a
        wh0 = where(power2a eq 0, count0)
        if count0 gt 0 then power_ratio1[wh0] = 0

        power1b = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i], 'power')
        power2b = getvar_savefile(compare_files.input_savefile2[slice_i, 2*i+1], 'power')

        power_ratio2 = power1b / power2b
        wh0 = where(power2b eq 0, count0)
        if count0 gt 0 then power_ratio2[wh0] = 0

        power_diff_ratio = power_ratio1-power_ratio2
        if n_elements(diff_range) lt 2 then begin
          diff_range = minmax(power_diff_ratio)
        endif

        if i eq 0 then begin
          ncol=3
          nrow=compare_files.n_sets/2
          start_multi_params = {ncol:ncol, nrow:nrow, ordering:'row'}
          undefine, pos_use
          if plot_options.pub then plotfile_2d = compare_files.plotfiles_2d
        endif else pos_use = positions[*,3*i]

        if keyword_set(plot_slices) then begin
          power_use = power_ratio1
          title_use = compare_files.titles[i,0]

          kpower_slice_plot, power = power_use, multi_pos = pos_use, $
            start_multi_params = start_multi_params, $
            xarr = xarr, yarr = yarr, slice_axis = slice_axis, $
            kperp_lambda_conv = kperp_lambda_conv, delay_params = delay_params, $
            hubble_param = hubble_param, $
            plot_options = plot_options, plot_2d_options = plot_2d_options, $
            plotfile = plotfile_2d, window_num = window_num, $
            full_title = title_use, /pwr_ratio, $
            wedge_amp = compare_files.wedge_amp

        endif else begin
          kpower_2d_plots, power = power_ratio1, multi_pos = pos_use, $
            start_multi_params = start_multi_params, $
            kperp_edges = kperp_edges, kpar_edges = kpar_edges, kperp_bin = kperp_bin, $
            kpar_bin = kpar_bin, $
            kperp_lambda_conv = kperp_lambda_conv, delay_params = delay_params, $
            hubble_param = hubble_param, $
            plot_options = plot_options, plot_2d_options = plot_2d_options, $
            plotfile = plotfile_2d, window_num = window_num, $
            full_title = compare_files.titles[i,0], /pwr_ratio, $
            wedge_amp = compare_files.wedge_amp
        endelse

        if i eq 0 then begin
          positions = pos_use
          undefine, start_multi_params
        endif
        pos_use = positions[*,3*i+1]

        if keyword_set(plot_slices) then begin
          power_use = power_ratio2
          title_use = compare_files.titles[i,1]

          kpower_slice_plot, power = power_use, multi_pos = pos_use, $
            start_multi_params = start_multi_params, $
            xarr = xarr, yarr = yarr, slice_axis = slice_axis, $
            kperp_lambda_conv = kperp_lambda_conv, delay_params = delay_params, $
            hubble_param = hubble_param, $
            plot_options = plot_options, plot_2d_options = plot_2d_options, $
            plotfile = plotfile_2d, window_num = window_num, $
            full_title = title_use, /pwr_ratio, $
            wedge_amp = compare_files.wedge_amp
        endif else begin
          kpower_2d_plots, power = power_ratio2, multi_pos = pos_use, $
            start_multi_params = start_multi_params, $
            kperp_edges = kperp_edges, kpar_edges = kpar_edges, $
            kperp_bin = kperp_bin, kpar_bin = kpar_bin, $
            kperp_lambda_conv = kperp_lambda_conv, delay_params = delay_params, $
            hubble_param = hubble_param, $
            plot_options = plot_options, plot_2d_options = plot_2d_options, $
            plotfile = plotfile_2d, window_num = window_num, $
            full_title = compare_files.titles[i,1], /pwr_ratio, $
            wedge_amp = compare_files.wedge_amp
        endelse

        pos_use = positions[*,3*i+2]

        if keyword_set(plot_slices) then begin
          power_use = power_diff_ratio
          title_use = compare_files.titles[i,2]

          kpower_slice_plot, power = power_use, multi_pos = pos_use, $
            start_multi_params = start_multi_params, $
            xarr = xarr, yarr = yarr, slice_axis = slice_axis, $
            kperp_lambda_conv = kperp_lambda_conv, delay_params = delay_params, $
            hubble_param = hubble_param, data_range = diff_range, $
            plot_options = plot_options, plot_2d_options = plot_2d_options, $
            plotfile = plotfile_2d, window_num = window_num, color_profile = 'sym_log', $, $
            data_min_abs = diff_min_abs, full_title = title_use, $
            wedge_amp = compare_files.wedge_amp
        endif else begin
          kpower_2d_plots, power = power_diff_ratio, multi_pos = pos_use, $
            start_multi_params = start_multi_params, $
            kperp_edges = kperp_edges, kpar_edges = kpar_edges, $
            kperp_bin = kperp_bin, kpar_bin = kpar_bin, $
            kperp_lambda_conv = kperp_lambda_conv, delay_params = delay_params, $
            hubble_param = hubble_param, data_range = diff_range, $
            plot_options = plot_options, plot_2d_options = plot_2d_options, $
            plotfile = plotfile_2d, window_num = window_num, color_profile = 'sym_log', $
            data_min_abs = diff_min_abs, full_title = compare_files.titles[i,2], $
            note = plot_options.note + ', ' + compare_files.kperp_density_names, $
            wedge_amp = compare_files.wedge_amp
        endelse

      endfor

      if plot_options.pub then begin
        cgps_close, png = plot_options.png, pdf = plot_options.pdf, $
          delete_ps = plot_options.delete_ps, density=600
      endif

    endif else begin
      if plot_options.pub then plotfile_2d = compare_files.plotfiles_2d

      if keyword_set(plot_slices) then begin
        slice_axis = getvar_savefile(compare_files.input_savefile1[slice_i], 'slice_axis')

        kpower_slice_plot, [compare_files.input_savefile1[slice_i], $
          compare_files.input_savefile2[slice_i]], $
          plot_options = plot_options, plot_2d_options = plot_2d_options, $
          plotfile = plotfile_2d, window_num = window_num, $
          title_prefix = compare_files.titles, note = plot_options.note + ', ' + compare_files.kperp_density_names, $
          /pwr_ratio, wedge_amp = compare_files.wedge_amp
      endif else begin
        kpower_2d_plots, [compare_files.input_savefile1[slice_i], $
          compare_files.input_savefile2[slice_i]], $
          plot_options = plot_options, plot_2d_options = plot_2d_options, $
          plotfile = plotfile_2d, window_num = window_num, $
          title_prefix = compare_files.titles, note = plot_options.note + ', ' + compare_files.kperp_density_names, $
          /pwr_ratio, wedge_amp = compare_files.wedge_amp
      endelse

    endelse
    window_num += 1
  endfor
end
