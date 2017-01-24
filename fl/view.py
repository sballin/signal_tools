import os
import scipy.io.idl 
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
from matplotlib.widgets import Slider, Button
from phantom_viewer import acquire
from phantom_viewer import signals
from phantom_viewer import process
import scipy.optimize
import glob


def make_colormap(seq):
    """
    Return a LinearSegmentedColormap.
    
    Args:
        seq: a sequence of floats and RGBA-tuples. The floats should be 
        increasing and in the interval (0,1).
    """
    seq = [(None,) * 4, 0.0] + list(seq) + [1.0, (None,) * 4]
    cdict = {'red': [], 'green': [], 'blue': [], 'alpha': []}
    for i, item in enumerate(seq):
        if isinstance(item, float):
            r1, g1, b1, a1= seq[i - 1]
            r2, g2, b2, a2 = seq[i + 1]
            cdict['red'].append([item, r1, r2])
            cdict['green'].append([item, g1, g2])
            cdict['blue'].append([item, b1, b2])
            cdict['alpha'].append([item, a1, a2])
    return matplotlib.colors.LinearSegmentedColormap('CustomMap', cdict)


def slide_reconstruct_corr(shot, fl_sav):
    """
    Slide through Phantom camera frames using given synthetic field line images 
    to create a reconstruction of the original using cross-correlation to find
    the best match.
    
    Args:
        shot: [int] shot number
        fl_sav: [scipy.io.idl.readsav object] containing field line images
    """
    time = acquire.gpi_series(shot, 'phantom2', 'time')
    frames = acquire.video(shot, 'phantom2', sub=20, sobel=False)
    frame_index = 0
    fls = fl_sav.fl_image
    fl_r = fl_sav.fieldline_r
    fl_z = fl_sav.fieldline_z
    rlcfs, zlcfs = acquire.lcfs_rz(shot)
    efit_times, flux, flux_extent = acquire.time_flux_extent(shot)
    efit_t_index = process.find_nearest(efit_times, time[0])
    machine_x, machine_y = acquire.machine_cross_section()

    # Find cross-correlation scores between frames and field line images
    xcorrs = np.zeros(fls.shape[0])
    for i, fl in enumerate(fls):
        xcorrs[i] = signals.cross_correlation(frames[frame_index], fl) 
    indices = np.argsort(xcorrs)

    # Interpolate field line cross-correlation scores over R, Z grid
    r_space = np.linspace(min(fl_r), max(fl_r), 100)
    z_space = np.linspace(min(fl_z), max(fl_z), 100)
    r_grid, z_grid = np.meshgrid(r_space, z_space)
    xcorr_grid = matplotlib.mlab.griddata(fl_r, fl_z, xcorrs, r_grid, z_grid, 
                                          interp='linear')

    # Plot camera image with field line overlay
    fig, ax = plt.subplots()
    fig.suptitle('Shot {}'.format(shot))

    plt.subplot(121)
    plt.title('Divertor camera view')
    plasma_image = plt.imshow(frames[frame_index], cmap=plt.cm.gray, 
                              origin='bottom')
    overlay_cmap = make_colormap([(1., 0., 0., 0.), (1., 0., 0., 1.)])
    fl_image = plt.imshow(fls[indices[-1]], cmap=overlay_cmap, origin='bottom',
                          alpha=0.8)
    plt.axis('off')

    # Plot field line R, Z data in context of machine
    plt.subplot(122)
    plt.title('Toroidal cross section')
    xcorr_image = plt.pcolormesh(r_grid, z_grid, xcorr_grid)
    colorbar = plt.colorbar()
    colorbar.set_label('Cross-correlation')
    plt.plot(machine_x, machine_y, color='gray')
    l, = plt.plot(rlcfs[efit_t_index], zlcfs[efit_t_index], color='fuchsia')
    plt.axis('equal')
    plt.xlim([.49, .62])
    plt.ylim([-.50, -.33])
    plt.xlabel('R (m)')
    plt.ylabel('Z (m)')
    f, = plt.plot(fl_r[indices[-1]], fl_z[indices[-1]], 'ro')
    plt.contour(flux[efit_t_index], 100, extent=flux_extent)
    
    # Slider and button settings
    fl_slide_area = plt.axes([0.20, 0.02, 0.60, 0.03])
    fl_slider = Slider(fl_slide_area, 'Correlation rank', 0, len(fls)-1, 
                       valinit=0)
    fl_slider.valfmt = '%d'
    gpi_slide_area = plt.axes([0.20, 0.06, 0.60, 0.03])
    gpi_slider = Slider(gpi_slide_area, 'Camera frame', 0, len(frames)-1,
                        valinit=0)
    gpi_slider.valfmt = '%d'
    forward_button_area = plt.axes([0.95, 0.06, 0.04, 0.04])
    forward_button = Button(forward_button_area, '>')
    back_button_area = plt.axes([0.95, 0.01, 0.04, 0.04])
    back_button = Button(back_button_area, '<')

    def update_data(val):
        global frame_index, indices, xcorr_grid
        frame_index = int(val)
        for i, fl in enumerate(fls):
            xcorrs[i] = signals.cross_correlation(frames[frame_index], fl) 
        xcorr_grid = matplotlib.mlab.griddata(fl_r, fl_z, xcorrs, r_grid, 
                                              z_grid, interp='linear')
        indices = np.argsort(xcorrs)[::-1]
        update_images(0)
    
    def update_images(val):
        global frame_index, indices, xcorr_grid
        val = int(val)
        efit_t_index = process.find_nearest(efit_times, time[frame_index])
        plasma_image.set_array(frames[frame_index])
        plasma_image.autoscale()
        fl_image.set_array(fls[indices[val]])
        fl_image.autoscale()
        f.set_xdata(fl_r[indices[val]])
        f.set_ydata(fl_z[indices[val]])
        l.set_xdata(rlcfs[efit_t_index])
        l.set_ydata(zlcfs[efit_t_index])
        xcorr_image.set_array(xcorr_grid[:-1, :-1].ravel())
        fig.canvas.draw_idle()

    def forward(event):
        global frame_index
        frame_index += 1
        update_data(frame_index)

    def backward(event):
        global frame_index
        frame_index -= 1
        update_data(frame_index)
    
    fl_slider.on_changed(update_images)
    gpi_slider.on_changed(update_data)
    forward_button.on_clicked(forward)
    back_button.on_clicked(backward)

    plt.tight_layout(rect=(0, .1, 1, .9))
    plt.show()
        
        
def slide_reconstruct(shot, fl_sav, smoothing_param=5000):
    """
    Slide through Phantom camera frames using given synthetic field line images 
    to create a reconstruction of the original using non-negative least squares
    (NNLS) fitting. The NNLS method used here is slow, so there are long delays 
    between clicks and interface updates.
    
    Args:
        shot: [int] shot number
        fl_sav: [scipy.io.idl.readsav object] containing field line images
        smoothing_param: [float] least-squares smoothing parameter
    """
    time = acquire.gpi_series(shot, 'phantom2', 'time')
    frames = acquire.video(shot, 'phantom2', sub=20, sobel=False)
    frame_index = 0
    fl_images = fl_sav.fl_image
    fl_r = fl_sav.fieldline_r
    fl_z = fl_sav.fieldline_z
    rlcfs, zlcfs = acquire.lcfs_rz(shot)
    efit_times, flux, flux_extent = acquire.time_flux_extent(shot)
    efit_t_index = process.find_nearest(efit_times, time[0])
    machine_x, machine_y = acquire.machine_cross_section()

    inversion_func = scipy.optimize.nnls
    geomatrix = np.transpose(np.array([fl.flatten() for fl in fl_images]))
    geomatrix_smooth = np.concatenate((geomatrix, 
                                       smoothing_param*np.identity(len(fl_images))))
    target = frames[0]
    target_smooth = np.concatenate((target.flatten(), np.zeros(len(fl_images))))
    inv = inversion_func(geomatrix_smooth, target_smooth)

    r_space = np.linspace(min(fl_r), max(fl_r), 100)
    z_space = np.linspace(min(fl_z), max(fl_z), 100)
    r_grid, z_grid = np.meshgrid(r_space, z_space)
    emissivity_grid = matplotlib.mlab.griddata(fl_r, fl_z, inv[0], r_grid,
                                               z_grid, interp='linear') 

    reconstructed = geomatrix.dot(inv[0])
    reconstructed = reconstructed.reshape((64,64))
    target = target.reshape((64,64))
    fig, ax = plt.subplots()
    
    plt.subplot(221)
    plt.title('Divertor camera view')
    plasma_image = plt.imshow(target, cmap=plt.cm.gist_heat, origin='bottom')
    plt.axis('off')
    plt.colorbar()
    
    plt.subplot(222)
    plt.title('Reconstruction')
    reconstruction_image = plt.imshow(reconstructed, cmap=plt.cm.gist_heat, origin='bottom')
    plt.axis('off')
    plt.colorbar()
    
    plt.subplot(223)
    plt.title('Reconstruction minus original')
    error_image = plt.imshow(target - reconstructed, cmap=plt.cm.gist_heat, origin='bottom')
    plt.axis('off')
    plt.colorbar()
    
    plt.subplot(224)
    plt.title('Toroidal cross section')
    emissivity_image = plt.pcolormesh(r_grid, z_grid, emissivity_grid)
    colorbar = plt.colorbar()
    colorbar.set_label('Relative emissivity')
    plt.axis('equal')
    plt.plot(machine_x, machine_y, color='gray')
    l, = plt.plot(rlcfs[efit_t_index], zlcfs[efit_t_index], color='fuchsia')
    plt.xlim([.49, .62])
    plt.ylim([-.50, -.33])
    plt.xlabel('R (m)')
    plt.ylabel('Z (m)')
    plt.contour(flux[efit_t_index], 100, extent=flux_extent)

    gpi_slide_area = plt.axes([0.20, 0.02, 0.60, 0.03])
    gpi_slider = Slider(gpi_slide_area, 'Camera frame', 0, len(frames)-1,
                        valinit=0)
    gpi_slider.valfmt = '%d'
    forward_button_area = plt.axes([0.95, 0.06, 0.04, 0.04])
    forward_button = Button(forward_button_area, '>')
    back_button_area = plt.axes([0.95, 0.01, 0.04, 0.04])
    back_button = Button(back_button_area, '<')

    def update_data(val):
        global frame_index, emissivity_grid, reconstructed
        frame_index = int(val)
        target_smooth = np.concatenate((frames[frame_index].flatten(), np.zeros(len(fl_images))))
        inv = inversion_func(geomatrix_smooth, target_smooth)
        # inv = inversion_func(geomatrix, target)
        reconstructed = geomatrix.dot(inv[0]).reshape((64,64))
        emissivity_grid = matplotlib.mlab.griddata(fl_r, fl_z, inv[0], r_grid, 
                                              z_grid, interp='linear')
        plasma_image.set_array(frames[frame_index])
        reconstruction_image.set_array(reconstructed)
        emissivity_image.set_array(emissivity_grid[:-1, :-1].ravel())
        error_image.set_array(frames[frame_index]-reconstructed)
        error_image.autoscale()
        plasma_image.autoscale()
        reconstruction_image.autoscale()
        emissivity_image.autoscale()
        efit_t_index = process.find_nearest(efit_times, time[frame_index])
        l.set_xdata(rlcfs[efit_t_index])
        l.set_ydata(zlcfs[efit_t_index])
        fig.canvas.draw_idle()

    def forward(event):
        global frame_index
        frame_index += 1
        update_data(frame_index)

    def backward(event):
        global frame_index
        frame_index -= 1
        update_data(frame_index)

    gpi_slider.on_changed(update_data)
    forward_button.on_clicked(forward)
    back_button.on_clicked(backward)

    plt.tight_layout(rect=(0, .1, 1, .9))
    plt.show()


def slide_reconstruction(shot):
    """
    Slide through Phantom camera frames and their reconstructions from
    synthetic field line images calculated externally with Julia.
    
    Args:
        shot: [int] shot number
        fl_sav: [scipy.io.idl.readsav object] containing field line images
    """
    # Read cache files
    old_working_dir = os.getcwd()
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    emissivity_files = sorted(glob.glob('../cache/fl_emissivities_Xpt_{}*'.format(shot)))
    emissivities = [np.load(f) for f in emissivity_files]
    # Field line starting R, Z is the same for all times
    fl_data_files = glob.glob('../cache/fl_data_Xpt_{}*'.format(shot))
    fl_data = scipy.io.idl.readsav(fl_data_files[0])
    fl_image_files = sorted(glob.glob('../cache/fl_images_Xpt_{}*'.format(shot)))
    fl_images = [np.load(f) for f in fl_image_files]
    os.chdir(old_working_dir)

    time = acquire.gpi_series(shot, 'phantom2', 'time')
    frames = acquire.video(shot, 'phantom2', sub=20, sobel=False)
    frame_index = 0
    fl_images = fl_sav.fl_image
    fl_r = fl_sav.fieldline_r
    fl_z = fl_sav.fieldline_z
    rlcfs, zlcfs = acquire.lcfs_rz(shot)
    efit_times, flux, flux_extent = acquire.time_flux_extent(shot)
    efit_t_index = process.find_nearest(efit_times, time[0])
    machine_x, machine_y = acquire.machine_cross_section()

    em = np.load('out.npz')['arr_0']

    geomatrix = np.transpose(np.array([fl.flatten() for fl in fl_images]))

    r_space = np.linspace(min(fl_r), max(fl_r), 100)
    z_space = np.linspace(min(fl_z), max(fl_z), 100)
    r_grid, z_grid = np.meshgrid(r_space, z_space)
    emissivity_grid = matplotlib.mlab.griddata(fl_r, fl_z, em[0].flatten(), r_grid,
                                               z_grid, interp='linear') 

    reconstructed = geomatrix.dot(em[0])
    reconstructed = reconstructed.reshape((64,64))
    target = frames[0]
    fig, ax = plt.subplots()
    
    plt.subplot(221)
    plt.title('Divertor camera view')
    plasma_image = plt.imshow(target, cmap=plt.cm.gist_heat, origin='bottom')
    plt.axis('off')
    plt.colorbar()
    
    plt.subplot(222)
    plt.title('Reconstruction')
    reconstruction_image = plt.imshow(reconstructed, cmap=plt.cm.gist_heat, origin='bottom')
    plt.axis('off')
    plt.colorbar()
    
    plt.subplot(223)
    plt.title('Reconstruction minus original')
    error_image = plt.imshow(target - reconstructed, cmap=plt.cm.gist_heat, origin='bottom')
    plt.axis('off')
    plt.colorbar()
    
    plt.subplot(224)
    plt.title('Toroidal cross section')
    emissivity_image = plt.pcolormesh(r_grid, z_grid, emissivity_grid)
    colorbar = plt.colorbar()
    colorbar.set_label('Relative emissivity')
    plt.axis('equal')
    plt.plot(machine_x, machine_y, color='gray')
    l, = plt.plot(rlcfs[efit_t_index], zlcfs[efit_t_index], color='fuchsia')
    plt.xlim([.49, .62])
    plt.ylim([-.50, -.33])
    plt.xlabel('R (m)')
    plt.ylabel('Z (m)')
    plt.contour(flux[efit_t_index], 100, extent=flux_extent)

    gpi_slide_area = plt.axes([0.20, 0.02, 0.60, 0.03])
    gpi_slider = Slider(gpi_slide_area, 'Camera frame', 0, len(frames)-1,
                        valinit=0)
    gpi_slider.valfmt = '%d'
    forward_button_area = plt.axes([0.95, 0.06, 0.04, 0.04])
    forward_button = Button(forward_button_area, '>')
    back_button_area = plt.axes([0.95, 0.01, 0.04, 0.04])
    back_button = Button(back_button_area, '<')

    def update_data(val):
        global frame_index, emissivity_grid, reconstructed
        frame_index = int(val)
        reconstructed = geomatrix.dot(em[frame_index]).reshape((64,64))
        emissivity_grid = matplotlib.mlab.griddata(fl_r, fl_z, em[frame_index].flatten(), r_grid, 
                                              z_grid, interp='linear')
        plasma_image.set_array(frames[frame_index])
        reconstruction_image.set_array(reconstructed)
        emissivity_image.set_array(emissivity_grid[:-1, :-1].ravel())
        error_image.set_array(frames[frame_index]-reconstructed)
        error_image.autoscale()
        plasma_image.autoscale()
        reconstruction_image.autoscale()
        emissivity_image.autoscale()
        efit_t_index = process.find_nearest(efit_times, time[frame_index])
        l.set_xdata(rlcfs[efit_t_index])
        l.set_ydata(zlcfs[efit_t_index])
        fig.canvas.draw_idle()

    def forward(event):
        global frame_index
        frame_index += 1
        update_data(frame_index)

    def backward(event):
        global frame_index
        frame_index -= 1
        update_data(frame_index)

    gpi_slider.on_changed(update_data)
    forward_button.on_clicked(forward)
    back_button.on_clicked(backward)

    plt.tight_layout(rect=(0, .1, 1, .9))
    plt.show()

   
def main():
    shot = 1150611004 #1150923010 
    slide_reconstruction(shot)

if __name__ == '__main__':
    main()