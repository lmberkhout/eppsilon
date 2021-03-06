;;  Optionally, a plot_1d_options structure (created with create_plot_1d_options.pro)
;;    and/or a plot_options structure (created with create_plot_options.pro)
;;    can be passed which sets several of the keywords. If the keywords are set separately,
;;    the keyword values supercede the structure values.

pro kpower_1d_plots, power_savefile, multi_pos = multi_pos, $
    start_multi_params = start_multi_params, plotfile = plotfile, $
    plot_options = plot_options, plot_1d_options = plot_1d_options, $
    plot_weights = plot_weights, plot_noise = plot_noise, data_range = data_range, $
    k_range = k_range, png = png, eps = eps, pdf = pdf, $
    window_num = window_num, colors = colors, names = names, psyms = psyms, $
    save_text = save_text, delta = delta, hinv = hinv, note = note, title = title, $
    kpar_power = kpar_power, kperp_power = kperp_power, $
    yaxis_type = yaxis_type, plot_error_bars = plot_error_bars, $
    plot_sim_noise = plot_sim_noise, plot_nsigma = plot_nsigma, $
    delay_params = delay_params, delay_axis = delay_axis, $
    cable_length_axis = cable_length_axis, baseline_axis = baseline_axis, $
    no_text = no_text

  if n_elements(plot_options) gt 0 then begin
    if n_elements(hinv) eq 0 then hinv = plot_options.hinv
    if n_elements(note) eq 0 then note = plot_options.note
    if n_elements(png) eq 0 then png = plot_options.png
    if n_elements(eps) eq 0 then eps = plot_options.eps
    if n_elements(pdf) eq 0 then pdf = plot_options.pdf
  endif

  if n_elements(plot_1d_options) gt 0 then begin
    if n_elements(delta) eq 0 then delta = plot_1d_options.plot_1d_delta
    if n_elements(no_text) eq 0 then no_text = plot_1d_options.no_text_1d
    if n_elements(plot_error_bars) eq 0 then plot_error_bars = plot_1d_options.plot_1d_error_bars
    if n_elements(plot_nsigma) eq 0 and tag_exist(plot_1d_options, 'plot_1d_nsigma') then begin
      plot_nsigma = plot_1d_options.plot_1d_nsigma
    endif
    if n_elements(data_range) eq 0 and tag_exist(plot_1d_options, 'range_1d') then begin
      data_range = plot_1d_options.range_1d
    endif
  endif

  if n_elements(yaxis_type) eq 0 then yaxis_type = 'clipped_log'
  yaxis_type_list = ['clipped_log', 'sym_log', 'folded_log']
  wh_axis_type = where(yaxis_type_list eq yaxis_type, count_axis_type)
  if count_axis_type eq 0 then message, 'yaxis_type not recognized'

  if keyword_set(kpar_power) and keyword_set(kperp_power) then message, 'Only one of kpar_power and kperp_power can be set'

  if keyword_set(baseline_axis) and not keyword_set(kperp_power) then message, 'baseline_axis can only be set if kperp_power is set'
  if keyword_set(delay_axis) and keyword_set(cable_length_axis) then message, 'Only one of delay_axis and cable_length_axis can be set'
  if keyword_set(delay_axis) and not keyword_set(kpar_power) then message, 'delay_axis can only be set if kpar_power is set'
  if keyword_set(cable_length_axis) and not keyword_set(kpar_power) then message, 'cable_length_axis can only be set if kpar_power is set'

  if keyword_set(plot_weights) and keyword_set(plot_noise) then message, 'Only one of plot_weights and plot_noise can be set.'


  if n_elements(plotfile) gt 0 or keyword_set(png) or keyword_set(eps) or keyword_set(pdf) then pub = 1 else pub = 0
  if pub eq 1 then begin
    if not (keyword_set(png) or keyword_set(eps) or keyword_set(pdf)) then begin
      basename = cgRootName(plotfile, directory=directory, extension=extension)

      case extension of
        'eps': eps=1
        'png': png=1
        'pdf': pdf=1
        '': png = 1
        else: begin
          print, 'Unrecognized extension, using png'
          png = 1
        end
      endcase

    endif
    if n_elements(plotfile) eq 0 and n_elements(multi_pos) eq 0 then begin
      plotfile = strsplit(power_savefile[0], '.idlsave', /regex, /extract)
      cd, current = current_dir
      print, 'no filename specified for kpower_1d_plots output. Using ' + current_dir + path_sep() + plotfile
    endif

    if keyword_set(png) and keyword_set(eps) and keyword_set(pdf) then begin
      print, 'only one of eps, pdf and png can be set, using png'
      eps = 0
    endif

    if keyword_set(png) then begin
      plot_exten = '.png'
      delete_ps = 1
    endif else if keyword_set(pdf) then begin
      plot_exten = '.pdf'
      delete_ps = 1
    endif else if keyword_set(eps) then begin
      plot_exten = '.eps'
      delete_ps = 0
    endif

    if strcmp(strmid(plotfile, strlen(plotfile)-4), plot_exten, /fold_case) eq 0 then plotfile = plotfile + plot_exten
  endif

  if n_elements(window_num) eq 0 then window_num = 2

  if n_elements(plot_nsigma) eq 0 then plot_nsigma = 1 else if n_elements(plot_nsigma) gt 1 then message, 'plot_nsigma should be a scalar'

  if n_elements(start_multi_params) gt 0 and n_elements(multi_pos) gt 0 then message, 'If start_multi_params are passed, ' + $
    'multi_pos cannot be passed because then it is used as an output to pass back the positions for future plots.'

  if n_elements(multi_pos) gt 0 then begin
    if n_elements(multi_pos) ne 4 then message, 'multi_pos must be a 4 element plot position vector'
    if max(multi_pos) gt 1 or min(multi_pos) lt 0 then message, 'multi_pos must be in normalized coordinates (between 0 & 1)'
    if multi_pos[2] le multi_pos[0] or multi_pos[3] le multi_pos[1] then $
      message, 'In multi_pos, x1 must be greater than x0 and y1 must be greater than y0 '
  endif

  nfiles = n_elements(power_savefile)
  if n_elements(names) gt 0 and n_elements(names) ne nfiles then message, 'Number of names does not match number of files'
  if n_elements(colors) gt 0 and n_elements(colors) ne nfiles then message, 'Number of colors does not match number of files'
  if n_elements(psyms) gt 0 then begin
    if n_elements(psym) eq 1 then psyms = intarr(nfiles) + psyms
    if n_elements(psyms) ne nfiles then message, 'Number of psyms does not match number of files'
  endif else psyms = intarr(nfiles) + 10

  margin = [0.15, 0.2, 0.05, 0.1]
  if keyword_set(baseline_axis) or keyword_set(delay_axis) or keyword_set(cable_length_axis) or keyword_set(no_text) then begin
    margin[3] = 0.15
    initial_title = ''
  endif else initial_title = title
  plot_pos = [margin[0], margin[1], (1-margin[2]), (1-margin[3])]

  ;; set aspect ratio to 1
  aspect_ratio=1.
  x_factor=1.
  y_factor=1.

  screen_size = get_screen_size()
  max_xsize = screen_size[0]
  max_ysize = screen_size[1]
  base_size = 600
  if n_elements(multi_pos) eq 4 then begin
    ;; work out positions scaled to the area allowed in multi_pos with proper aspect ratio
    multi_xlen = (multi_pos[2]-multi_pos[0])
    multi_ylen = (multi_pos[3]-multi_pos[1])
    multi_center = [multi_pos[0] + multi_xlen/2d, multi_pos[1] + multi_ylen/2d]

    multi_size = [!d.x_vsize*multi_xlen, !d.y_vsize*multi_ylen]
  endif

  if n_elements(multi_pos) eq 4 or n_elements(start_multi_params) gt 0 then begin
    if n_elements(start_multi_params) gt 0 then begin
      ;; calculate desired window size and positions for all plots
      ncol = start_multi_params.ncol
      nrow = start_multi_params.nrow

      multi_pos = fltarr(4, ncol*nrow)

      if tag_exist(start_multi_params, 'ordering') eq 0 then ordering = 'row' $
      else ordering = start_multi_params.ordering

      case ordering of
        'col': begin
          ;; col-major values
          col_val = reform(rebin(reform(indgen(ncol), 1, ncol), nrow, ncol), ncol*nrow)
          row_val = reverse(reform(rebin(indgen(nrow), nrow, ncol), ncol*nrow))
        end
        'row': begin
          ;; row-major values
          col_val = reform(rebin(indgen(ncol), ncol, nrow), ncol*nrow)
          row_val = reverse(reform(rebin(reform(indgen(nrow), 1, nrow), ncol, nrow), ncol*nrow))
        end
        else: message, 'unrecognized ordering value in start_multi_params, use "col" or "row" '
      endcase

      multi_pos[0,*] = col_val/double(ncol)
      multi_pos[1,*] = row_val/double(nrow)
      multi_pos[2,*] = (col_val+1)/double(ncol)
      multi_pos[3,*] = (row_val+1)/double(nrow)

      ;; define window size based on aspect ratio
      base_size_use = base_size
      xsize = round(base_size * x_factor * double(ncol))
      ysize = round(base_size * y_factor * double(nrow))
      if not keyword_set(pub) then begin
        while (ysize gt max_ysize) or (xsize gt max_xsize) do begin
          if base_size_use gt 100 then base_size_use = base_size_use - 100 else base_size_use = base_size_use * .75
          xsize = round(base_size_use * x_factor * double(ncol))
          ysize = round(base_size_use * y_factor * double(nrow))
        endwhile
      endif

      ;; if pub is set, start ps output
      if keyword_set(pub) then begin
        ps_aspect = (y_factor * float(nrow)) / (x_factor * float(ncol))

        if ps_aspect lt 1 then landscape = 1 else landscape = 0
        IF Keyword_Set(eps) THEN landscape = 0
        sizes = cgpswindow(LANDSCAPE=landscape, aspectRatio = ps_aspect, /sane_offsets)

        cgps_open, plotfile, /font, encapsulated=eps, /nomatch, inches=sizes.inches, xsize=sizes.xsize, ysize=sizes.ysize, $
          xoffset=sizes.xoffset, yoffset=sizes.yoffset, landscape = landscape

      endif else begin
        ;; make or set window
        if windowavailable(window_num) then begin
          wset, window_num
          if !d.x_size ne xsize or !d.y_size ne ysize then make_win = 1 else make_win = 0
        endif else make_win = 1
        if make_win eq 1 then window, window_num, xsize = xsize, ysize = ysize
        cgerase, background_color
      endelse

      ;; calculate multi_size & multi x/ylen not calculated earlier
      multi_xlen = (multi_pos[2,0]-multi_pos[0,0])
      multi_ylen = (multi_pos[3,0]-multi_pos[1,0])
      multi_center = [multi_pos[0,0] + multi_xlen/2d, multi_pos[1,0] + multi_ylen/2d]

      multi_size = [!d.x_vsize*multi_xlen, !d.y_vsize*multi_ylen]

      multi_pos_use = multi_pos[*,0]
    endif else multi_pos_use = multi_pos

    multi_aspect = multi_size[1]/float(multi_size[0])

    new_aspect = aspect_ratio/multi_aspect
    if new_aspect gt 1 then begin
      y_factor = 1.
      x_factor = 1/new_aspect
    endif else begin
      y_factor = new_aspect
      x_factor = 1.
    endelse

    new_xlen = multi_xlen*x_factor
    new_ylen = multi_ylen*y_factor
    new_multi = [multi_center[0] - new_xlen/2d, multi_center[1] - new_ylen*y_factor/2d, $
      multi_center[0] + new_xlen/2d, multi_center[1] + new_ylen*y_factor/2d]

    new_pos = [new_xlen * plot_pos[0] + new_multi[0], new_ylen * plot_pos[1] + new_multi[1], $
      new_xlen * plot_pos[2] + new_multi[0], new_ylen * plot_pos[3] + new_multi[1]]

    plot_pos = new_pos

    no_erase = 1
  endif else begin
    xsize = round(base_size * x_factor)
    ysize = round(base_size * y_factor)

    if keyword_set(pub) then begin
      ps_aspect = y_factor / x_factor

      if ps_aspect lt 1 then landscape = 1 else landscape = 0
      IF Keyword_Set(eps) THEN landscape = 0
      sizes = cgpswindow(LANDSCAPE=landscape, aspectRatio = ps_aspect, /sane_offsets)

      cgps_open, plotfile, /font, encapsulated=eps, /nomatch, inches=sizes.inches, xsize=sizes.xsize, ysize=sizes.ysize, $
        xoffset=sizes.xoffset, yoffset=sizes.yoffset, landscape = landscape

    ;cgps_open, plotfile, /font, encapsulated=eps, landscape=1, pagetype='letter'

    endif else begin
      while (ysize gt max_ysize) or (xsize gt max_xsize) do begin
        base_size = base_size - 100
        xsize = round(base_size * x_factor)
        ysize = round(base_size * y_factor)
      endwhile


      if windowavailable(window_num) then begin
        wset, window_num
        if !d.x_size ne xsize or !d.y_size ne ysize then make_win = 1 else make_win = 0
      endif else make_win = 1
      if make_win eq 1 then window, window_num, xsize = xsize, ysize = ysize
      cgerase, background_color
    endelse

    no_erase = 0
  endelse

  if yaxis_type eq 'sym_log' then begin
    ymid = plot_pos[1] + (plot_pos[3]-plot_pos[1])/2.
    positive_plot_pos = [plot_pos[0], ymid, plot_pos[2], plot_pos[3]]
    negative_plot_pos = [plot_pos[0], plot_pos[1], plot_pos[2], ymid]

    xloc_ytitle = plot_pos[0] - margin[0]/2.
    yloc_ytitle = ymid
  endif



  color_list = ['black', 'PBG5', 'red6', 'GRN3', 'PURPLE', 'ORANGE', 'TG2','TG8', 'blue', 'olive drab', 'coral', 'magenta']

  if n_elements(colors) eq 0 then begin
    if nfiles gt n_elements(color_list) then colors = indgen(nfiles)*254/(nfiles-1) $
    else colors = color_list[indgen(nfiles)]
  endif

  if keyword_set(save_text) then begin
    text_filename = strsplit(plotfile, plot_exten, /regex, /extract) + '.txt'
    if nfiles gt 1 then if n_elements(names) ne 0 then text_labels = names else text_labels = strarr(nfiles)

    openw, lun, text_filename, /get_lun
  endif


  for i=0, nfiles-1 do begin
    restore, power_savefile[i]

    n_k = n_elements(power)

    if keyword_set(plot_weights) then begin
      if n_elements(weights) ne 0 then power = weights $
      else message, 'No weights array included in this file'
    endif else if keyword_set(plot_noise) then begin
      if n_elements(noise) ne 0 then power = noise $
      else message, 'No noise array included in this file'
    endif

    if n_elements(weights) eq 0 then begin
      print, 'no weights in file ' + power_savefile[i] + ', using 1s'
      weights = fltarr(n_elements(power)) + 1
    endif

    sigma_val = sqrt(1./weights)
    wh_wt0 = where(weights eq 0, count_wt0)
    if count_wt0 gt 0 then sigma_val[wh_wt0] = 0

    ;; set sigma level to plot
    sigma_val = sigma_val * plot_nsigma

    if keyword_set(hinv) then begin
      if n_elements(k_edges) ne 0 then k_edges = k_edges / hubble_param
      if n_elements(k_centers) ne 0 then k_centers = k_centers / hubble_param
      if not keyword_set(plot_weights) then power = power * (hubble_param)^3d
      sigma_val = sigma_val * (hubble_param)^3d
      if n_elements(sim_noise) gt 0 and keyword_set(plot_sim_noise) then sim_noise = sim_noise * (hubble_param)^3d
    endif

    if keyword_set(kpar_power) then begin
      lin_delay_kpar_slope = (delay_params[1] - delay_params[0])/(max(k_edges) - k_bin)
      lin_delay_kpar_intercept = delay_params[0] / (lin_delay_kpar_slope * k_bin)
      linear_delay_edges = lin_delay_kpar_slope * k_edges + lin_delay_kpar_intercept

      log_delay_kpar_slope = (alog10(delay_params[1]) - alog10(delay_params[0]))/(alog10(max(k_edges)) - alog10(k_bin))
      log_delay_kpar_intercept = alog10(delay_params[0]) / (log_delay_kpar_slope * alog10(k_bin))
      log_delay_edges = 10^(log_delay_kpar_slope * alog10(k_edges) + log_delay_kpar_intercept)

    endif

    log_bins = 1
    if n_elements(k_centers) ne 0 then k_log_diffs = (alog10(k_centers) - shift(alog10(k_centers), 1))[2:*] $
    else k_log_diffs = (alog10(k_edges) - shift(alog10(k_edges), 1))[2:*]
    if total(abs(k_log_diffs - k_log_diffs[0])) gt n_k*1e-15 then log_bins = 0

    if n_elements(k_centers) ne 0 then begin
      k_mid = k_centers
      if n_elements(k_edges) eq 0 then begin
        if log_bins then begin
          k_bin = alog10(k_centers[2])-alog10(k_centers[1])
          k_edges = 10^([alog10(k_centers) - k_bin, alog10(max(k_centers)) + k_bin])
          if keyword_set(kpar_power) then delay_edges = log_delay_edges
        endif else begin
          k_bin = k_centers[2] - k_centers[1]
          k_edges = [k_centers - k_bin, max(k_centers) + k_bin]
          if keyword_set(kpar_power) then delay_edges = linear_delay_edges
        endelse
      endif
    endif else begin
      if n_elements(k_bin) eq 0 then $
        if log_bins then k_bin = alog10(k_edges[2])-alog10(k_edges[1]) else k_bin = k_edges[2] - k_edges[1]
      if log_bins then k_mid = 10^(alog10(k_edges[1:*]) - k_bin/2.) else k_mid = k_edges[1:*] - k_bin/2.
      if keyword_set(kpar_power) then if log_bins then delay_edges = log_delay_edges else delay_edges = linear_delay_edges
    endelse

    ;; limit to k_range if set
    if keyword_set(k_range) then begin
      wh_k_inrange = where(k_edges ge k_range[0] and k_edges[1:*] le k_range[1], n_k_plot)

      if n_k_plot eq 0 then message, 'No data in plot k range'

      if n_k_plot ne n_k then begin
        power = power[wh_k_inrange]
        sigma_val = sigma_val[wh_k_inrange]
        if n_elements(sim_noise) gt 0 and keyword_set(plot_sim_noise) then sim_noise = sim_noise[wh_k_inrange]
        k_mid = k_mid[wh_k_inrange]
        temp = [wh_k_inrange, wh_k_inrange[n_k_plot-1]+1]
        k_edges = k_edges[temp]
        if keyword_set(kpar_power) then delay_edges = delay_edges[temp]
        n_k = n_k_plot
      endif

    endif

    theory_delta2 = power * k_mid^3d / (2d*!pi^2d)
    theory_delta2_sigma = sigma_val * k_mid^3d / (2d*!pi^2d)
    if n_elements(sim_noise) gt 0 and keyword_set(plot_sim_noise) then theory_delta2_sim_noise = sim_noise * k_mid^3d / (2d*!pi^2d)

    if keyword_set(save_text) then begin
      if keyword_set(hinv) then printf, lun,  text_labels[i]+ ' k (h Mpc^-1)' $
      else printf, lun,  text_labels[i]+ ' k (Mpc^-1)'
      printf, lun, transpose(k_mid)
      printf, lun, ''
      if keyword_set(delta) then begin
        printf, lun,  text_labels[i]+ ' delta^2 (k^3 Pk/(2pi^2)) -- mk^2)'
        printf, lun, transpose(theory_delta)
      endif else begin
        if keyword_set(hinv) then printf, lun, text_labels[i] + ' power (mk^2 h^-3 Mpc^3)' $
        else printf, lun,  text_labels[i]+ ' power (mk^2 Mpc^3)'
        printf, lun, transpose(power)
      endelse
      printf, lun, ''
    endif

    if keyword_set(delta) then begin
      power = theory_delta2
      sigma_val = theory_delta2_sigma
      if n_elements(sim_noise) gt 0 and keyword_set(plot_sim_noise) then sim_noise = theory_delta2_sim_noise
    endif

    wh_zero = where(power eq 0d, count_zero, complement = wh_non0, ncomplement = count_non0)
    if count_non0 eq 0 then begin
      print, 'No non-zero power'
      return
    endif
    if count_zero gt 0 then begin
      ;; only want to drop 0 bins at the edges.
      wh_keep = indgen(max(wh_non0) - min(wh_non0) + 1) + min(wh_non0)

      power = power[wh_keep]
      sigma_val = sigma_val[wh_keep]
      if n_elements(sim_noise) gt 0 and keyword_set(plot_sim_noise) then sim_noise = sim_noise[wh_keep]
      k_mid = k_mid[wh_keep]
      k_edges = k_edges[[wh_keep, max(wh_keep)+1]]
      if keyword_set(kpar_power) then delay_edges = delay_edges[[wh_keep, max(wh_keep)+1]]

      wh_zero = where(power eq 0d, count_zero, complement = wh_non0, ncomplement = count_non0)
    endif

    ;; extend arrays for plotting full histogram bins if plotting w/ psym=10
    if psyms[i] eq 10 then begin
      if min(k_edges) gt 0 then k_mid = [min(k_edges), k_mid, max(k_edges)] $
      else k_mid = [10^(alog10(k_mid[0])-k_log_diffs[0]), k_mid, max(k_edges)]
      if keyword_set(kpar_power) then begin
        if min(delay_edges) le 0 then begin
          delay_log_diffs = (alog10(delay_edges) - shift(alog10(delay_edges), 1))[2:*]
          delay_edges = [10^(alog10(delay_edges[1])-delay_log_diffs[0]), delay_edges[1:*]]
        endif
      endif
      power = [power[0], power, power[n_elements(power)-1]]
      sigma_val = [sigma_val[0], sigma_val, sigma_val[n_elements(sigma_val)-1]]
      if n_elements(sim_noise) gt 0 and keyword_set(plot_sim_noise) then sim_noise = [sim_noise[0], sim_noise, sim_noise[n_elements(sim_noise)-1]]
    endif

    wh_neg = where(power lt 0d, count_neg)
    wh_pos = where(power gt 0d, count_pos)
    if count_pos gt 0 then pos_range = minmax(power[wh_pos])
    if count_neg gt 0 then neg_range = minmax(power[wh_neg])
    wh_n0 = where(abs(power) gt 0d, count_n0)
    if count_n0 gt 0 then abs_range = minmax(abs(power[wh_n0]))

    if count_pos eq 0 and yaxis_type eq 'clipped_log' then message, 'No positive power and yaxis_type is clipped_log'

    wh_sigma_n0 = where(sigma_val gt 0, count_sigma_n0)
    if count_sigma_n0 eq 0 then message, 'sigma is zero everywhere'
    sigma_pos_range = minmax(sigma_val[wh_sigma_n0])

    tag = 'f' + strsplit(string(i),/extract)
    if i eq 0 then begin
      if n_elements(data_range) eq 0 then begin
        if yaxis_type ne 'clipped_log' then range_use = pos_range else range_use = abs_range

        yrange = 10.^([floor(alog10(min([range_use[0], sigma_pos_range[0]]))), $
          ceil(alog10(max([range_use[1], sigma_pos_range[1]])))])
      endif else begin
        yrange = data_range
      endelse
      if n_elements(k_range) eq 0 then xrange = minmax(k_mid) else begin
        if min(k_range) le 0 then xrange = [min(k_mid), max(k_range)] else xrange = k_range
      endelse

      power_plot = create_struct(tag, power)
      sigma_plot = create_struct(tag, sigma_val)
      if n_elements(sim_noise) gt 0 and keyword_set(plot_sim_noise) then sim_noise_plot = create_struct(tag, abs(sim_noise))
      k_plot = create_struct(tag, k_mid)

      if yaxis_type ne 'clipped_log' then begin
        n_pos = [count_pos]
        pos_locs = create_struct(tag, wh_pos)

        n_neg = [count_neg]
        neg_locs = create_struct(tag, wh_neg)

        n_zero = [count_zero]
        zero_locs = create_struct(tag, wh_zero)
      endif

    endif else begin
      if n_elements(data_range) eq 0 then begin
        if yaxis_type ne 'clipped_log' then range_use = pos_range else range_use = abs_range

        yrange = minmax([yrange, 10.^([floor(alog10(min([range_use[0], sigma_pos_range[0]]))), $
          ceil(alog10(max([range_use[1], sigma_pos_range[1]])))])])
      endif
      if n_elements(k_range) eq 0 then begin
        xrange_new = minmax(k_mid)
        xrange = minmax([xrange, xrange_new])
      endif

      power_plot = create_struct(tag, power, power_plot)
      sigma_plot = create_struct(tag, sigma_val, sigma_plot)
      if n_elements(sim_noise) gt 0 and keyword_set(plot_sim_noise) then sim_noise_plot = create_struct(tag, abs(sim_noise), sim_noise_plot)
      k_plot = create_struct(tag, k_mid, k_plot)

      if yaxis_type ne 'clipped_log' then begin
        n_pos = [n_pos, count_pos]
        pos_locs = create_struct(tag, wh_pos, pos_locs)

        n_neg = [n_neg, count_neg]
        neg_locs = create_struct(tag, wh_neg, neg_locs)

        n_zero = [n_zero, count_zero]
        zero_locs = create_struct(tag, wh_zero, zero_locs)
      endif

    endelse

    undefine, power
    undefine, sigma_val, weights
    if n_elements(k_edges) ne 0 then undefine, k_edges
    if n_elements(k_centers) ne 0 then undefine, k_centers
  endfor

  xloc_note = .99
  yloc_note = 0 + 0.1* (plot_pos[1]-0)

  if keyword_set(save_text) then free_lun, lun

  tvlct, r, g, b, /get

  if keyword_set(pub) then begin
    charthick = 3
    thick = 3
    xthick = 3
    ythick = 3
    charsize = 2
    font = 1
    if nfiles gt 3 then legend_charsize = charsize / (nfiles/3d)  else legend_charsize = 2

    DEVICE, /ISOLATIN1
    perp_char = '!9' + String("136B) + '!X' ;"

  endif else if n_elements(multi_pos) eq 0 then begin
    if windowavailable(window_num) then wset, window_num else window, window_num

    perp_char = '!9' + string(120B) + '!X'
  endif

  ;;plot, k_plot, power_plot, /ylog, /xlog, xrange = xrange, xstyle=1
  plot_order = reverse(indgen(nfiles))
  if keyword_set(plot_weights) then begin
    ytitle = 'Weights'
  endif else begin
    if keyword_set(delta) then ytitle = textoidl('\Delta^2 (k^3 P_k /(2\pi^2)) (mK^2)', font = font) else begin
      if keyword_set(hinv) then ytitle = textoidl('P_k (mK^2 !8h!X^{-3} Mpc^3)', font = font) $
      else ytitle = textoidl('P_k (mK^2 Mpc^3)', font = font)
    endelse
  endelse
  if keyword_set(kpar_power) then begin
    if keyword_set(hinv) then xtitle = textoidl('k_{||} (!8h!X Mpc^{-1})', font = font) $
    else xtitle = textoidl('k_{||} (Mpc^{-1})', font = font)
  endif else if keyword_set(kperp_power) then begin
    if keyword_set (hinv) then xtitle = textoidl('k_{perp} (!8h!X Mpc^{-1})', font = font) $
    else xtitle = textoidl('k_{perp} (Mpc^{-1})', font = font)
    xtitle = repstr(xtitle, 'perp', perp_char)
  endif else begin
    if keyword_set(hinv) then xtitle = textoidl('k (!8h!X Mpc^{-1})', font = font) $
    else xtitle = textoidl('k (Mpc^{-1})', font = font)
  endelse


  if keyword_set(baseline_axis) or keyword_set(delay_axis) or keyword_set(cable_length_axis) then begin
    style = 9

    case 1 of
      keyword_set(baseline_axis): begin
        if keyword_set(hinv) then axis_range = minmax(xrange * hubble_param * kperp_lambda_conv) $
        else axis_range = minmax(xrange* kperp_lambda_conv)
        axis_title = 'baseline length ' + textoidl('(\lambda)', font = font)
      end
      keyword_set(delay_axis): begin
        axis_range = minmax(delay_edges)
        axis_title = 'delay (ns)'
      end
      keyword_set(cable_length_axis): begin
        cable_index_ref = 0.81
        ;; delay is in ns, factor of 2 to account for reflection bounce
        axis_range = minmax(delay_edges * cable_index_ref * 0.3)/2.
        axis_title = 'cable length (m)'
      end
    endcase

  endif else style = 1

  case yaxis_type of
    'sym_log': begin
      cgplot, k_plot.(plot_order[0]), power_plot.(plot_order[0]), position = positive_plot_pos, /ylog, /xlog, xrange = xrange, yrange = yrange, $
        xstyle=1, ystyle=1, axiscolor = 'black', title = initial_title, psym=psyms[0], xtickformat = '(A1)', /nodata,$
        ytickformat = 'exponent', thick = thick, charthick = charthick, xthick = xthick, ythick = ythick, charsize = charsize, $
        font = font, noerase = no_erase
      for i=0, nfiles - 1 do if n_pos[i] gt 0 then begin
        temp_plot = power_plot.(plot_order[i])
        if n_neg[i] gt 0 then temp_plot[wh_neg] = yrange[0]
        if n_zero[i] gt 0 then temp_plot[wh_zero] = yrange[0]
        cgplot, /overplot, k_plot.(plot_order[i]), temp_plot, psym=psyms[i], color = colors[i], $
          thick = thick
      endif
      cgtext, xloc_ytitle, yloc_ytitle, ytitle, /normal, alignment=0.5, orientation = 90, charsize = charsize, font = font

      if log_bins gt 0 then bottom = 1 else bottom = 0
      if n_elements(names) ne 0 then $
        al_legend, names, textcolor = colors, box = 0, /right, bottom = bottom, charsize = legend_charsize, charthick = charthick


      cgplot, k_plot.(plot_order[0]), -1*(power_plot.(plot_order[0])), position = negative_plot_pos, /ylog, /xlog, xrange = xrange, yrange = reverse(yrange), $
        xstyle=style, ystyle=1, axiscolor = 'black', psym=psyms[0], xtickformat = 'exponent', /nodata, $
        ytickformat = 'exponent', thick = thick, charthick = charthick, xthick = xthick, ythick = ythick, charsize = charsize, $
        font = font, /noerase

      if keyword_set(baseline_axis) or keyword_set(delay_axis) or keyword_set(cable_length_axis) then begin
        cgaxis, xaxis=1, xtickv = xticks_in2, xticks = x_nticks, xminor=n_minor, xrange = axis_range, xtickformat = xtickformat, $
          xthick = xthick, xtitle = axis_title, $
          charthick = charthick, ythick = ythick, charsize = charsize, font = font, xstyle = 1, color = annotate_color

      endif

      for i=0, nfiles - 1 do if n_neg[i] gt 0 then begin
        temp_plot = -1*(power_plot.(plot_order[i]))
        if n_pos[i] gt 0 then temp_plot[wh_pos] = yrange[0]
        if n_zero[i] gt 0 then temp_plot[wh_zero] = yrange[0]
        cgplot, /overplot, k_plot.(plot_order[i]), temp_plot, psym=psyms[i], color = colors[i], $
          thick = thick
      endif
    end
    'folded_log': begin

      cgplot, k_plot.(plot_order[0]), power_plot.(plot_order[0]), position = plot_pos, /nodata, /ylog, /xlog, xrange = xrange, yrange = yrange, $
        xstyle=style, ystyle=1, axiscolor = 'black', xtitle = xtitle, ytitle = ytitle, title = initial_title, psym=psyms[0], xtickformat = 'exponent', $
        ytickformat = 'exponent', thick = thick, charthick = charthick, xthick = xthick, ythick = ythick, charsize = charsize, $
        font = font, noerase = no_erase

      if keyword_set(baseline_axis) or keyword_set(delay_axis) or keyword_set(cable_length_axis) then begin
        cgaxis, xaxis=1, xtickv = xticks_in2, xticks = x_nticks, xminor=n_minor, xrange = axis_range, xtickformat = xtickformat, $
          xthick = xthick, xtitle = axis_title, $
          charthick = charthick, ythick = ythick, charsize = charsize, font = font, xstyle = 1, color = annotate_color

      endif

      for i=0, nfiles - 1 do begin
        if n_pos[i] gt 0 then begin
          temp_plot = power_plot.(plot_order[i])
          if n_neg[i] gt 0 then temp_plot[wh_neg] = yrange[0]
          if n_zero[i] gt 0 then temp_plot[wh_zero] = yrange[0]
          cgplot, /overplot, k_plot.(plot_order[i]), temp_plot, psym=psyms[i], color = colors[i], $
            thick = thick
        endif

        if n_neg[i] gt 0 then begin
          temp_plot = -1*(power_plot.(plot_order[i]))
          if n_pos[i] gt 0 then temp_plot[wh_pos] = yrange[0]
          if n_zero[i] gt 0 then temp_plot[wh_zero] = yrange[0]
          cgplot, /overplot, k_plot.(plot_order[i]), temp_plot, psym=psyms[i], color = colors[i], $
            thick = thick, linestyle=2
        endif
      endfor

      if log_bins gt 0 then bottom = 1 else bottom = 0
      if n_elements(names) ne 0 then $
        al_legend, names, textcolor = colors, box = 0, /right, bottom = bottom, charsize = legend_charsize, charthick = charthick


    end
    'clipped_log': begin

      cgplot, k_plot.(plot_order[0]), power_plot.(plot_order[0]), position = plot_pos, /ylog, /xlog, xrange = xrange, yrange = yrange, $
        xstyle=style, ystyle=1, axiscolor = 'black', xtitle = xtitle, ytitle = ytitle, title = initial_title, psym=psyms[0], xtickformat = 'exponent', $
        ytickformat = 'exponent', thick = thick, charthick = charthick, xthick = xthick, ythick = ythick, charsize = charsize, $
        font = font, noerase = no_erase

      if keyword_set(baseline_axis) or keyword_set(delay_axis) or keyword_set(cable_length_axis) then begin

        cgaxis, xaxis=1, xtickv = xticks_in2, xticks = x_nticks, xminor=n_minor, xrange = axis_range, xtickformat = xtickformat, $
          xthick = xthick, xtitle = axis_title, $
          charthick = charthick, ythick = ythick, charsize = charsize, font = font, xstyle = 1, color = annotate_color

      endif

      for i=0, nfiles - 1 do begin
        if keyword_set(plot_error_bars) then begin
          err_high = sigma_plot.(plot_order[i])
          err_low = sigma_plot.(plot_order[i]) < power_plot.(plot_order[i])*.99999

          cgplot, /overplot, k_plot.(plot_order[i]), power_plot.(plot_order[i]), psym=psyms[i], color = colors[i], $
            thick = thick, err_yhigh = err_high, err_ylow = err_low, err_thick = thick, err_width=0, /err_clip

          if n_elements(sim_noise_plot) gt 0 and keyword_set(plot_sim_noise) then begin
            err_high = sigma_plot.(plot_order[i])
            err_low = sigma_plot.(plot_order[i]) < sim_noise_plot.(plot_order[i])*.99999

            cgplot, /overplot, k_plot.(plot_order[i]), sim_noise_plot.(plot_order[i]), $
              psym=psyms[i], color = colors[i], thick = thick, linestyle=1, $
              err_yhigh = err_high, err_ylow = err_low, err_thick = thick, err_width=0, /err_clip, err_style = 1
          endif
        endif else begin
          cgplot, /overplot, k_plot.(plot_order[i]), power_plot.(plot_order[i]), psym=psyms[i], color = colors[i], $
            thick = thick
          cgplot, /overplot, k_plot.(plot_order[i]), sigma_plot.(plot_order[i]), psym=psyms[i], color = colors[i], $
            thick = thick, linestyle=2
          if n_elements(sim_noise_plot) gt 0 and keyword_set(plot_sim_noise) then cgplot, /overplot, k_plot.(plot_order[i]), sim_noise_plot.(plot_order[i]), $
            psym=psyms[i], color = colors[i], thick = thick, linestyle=1
        endelse
      endfor

      if log_bins gt 0 then bottom = 1 else bottom = 0
      if n_elements(names) ne 0 and not keyword_set(no_text) then $
        al_legend, [names, 'with ' + number_formatter(plot_nsigma) + ' sigma thermal noise'], textcolor = [colors, 'black'], $
        box = 0, /right, bottom = bottom, charsize = legend_charsize, charthick = charthick

    end
  endcase
  if n_elements(note) ne 0 and not keyword_set(no_text) then begin
    if keyword_set(pub) then char_factor = 0.75 else char_factor = 1
    cgtext, xloc_note, yloc_note, note, /normal, alignment=1, charsize = char_factor*charsize, font = font
  endif

  if (keyword_set(baseline_axis) or keyword_set(delay_axis) or keyword_set(cable_length_axis)) and not keyword_set(no_text) then begin
    xloc_title = (plot_pos[2] - plot_pos[0])/2. + plot_pos[0]
    yloc_title = plot_pos[3] + 0.6* (1-plot_pos[3])

    cgtext, xloc_title, yloc_title, title, /normal, alignment=0.5, charsize=1.2 * charsize, $
      color = annotate_color, font = font
  endif

  if keyword_set(pub) and n_elements(multi_pos) eq 0 then begin
    cgps_close, png = png, pdf = pdf, delete_ps = delete_ps, density=600
  endif

  tvlct, r, g, b

end
