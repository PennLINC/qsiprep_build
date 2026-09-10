.. include:: links.rst

QSIPrep component image builds
==============================

.. image:: https://circleci.com/gh/PennLINC/qsiprep_build/tree/master.svg?style=svg
  :target: https://circleci.com/gh/PennLINC/qsiprep_build/tree/master

This repository builds external component images consumed by QSIPrep and
QSIRecon base images. QSIPrep's application environment, including FSL and
ANTs, is created by Pixi in the QSIPrep repository and is not assembled here.

The legacy aggregate ``pennlinc/qsiprep_build`` image is retired. Releases from
this repository publish only the individual component images.


Full documentation at https://qsiprep.readthedocs.io

About
-----

``qsiprep`` configures pipelines for processing diffusion-weighted MRI (dMRI) data.
The main features of this software are

  1. A BIDS-app approach to preprocessing nearly all kinds of modern diffusion MRI data.
  2. Automatically generated preprocessing pipelines that correctly group, distortion correct,
     motion correct, denoise, coregister and resample your scans, producing visual reports and
     QC metrics.
  3. A system for running state-of-the-art reconstruction pipelines that include algorithms
     from Dipy_, MRTrix_, `DSI Studio`_  and others.
  4. A novel motion correction algorithm that works on DSI and random q-space sampling schemes

.. image:: https://github.com/PennLINC/qsiprep/raw/master/docs/_static/workflow_full.png


.. _preprocessing_def:

Preprocessing
~~~~~~~~~~~~~~~

The preprocessing pipelines are built based on the available BIDS inputs, ensuring that fieldmaps
are handled correctly. The preprocessing workflow performs head motion correction, susceptibility
distortion correction, MP-PCA denoising, coregistration to T1w images, spatial normalization
using ANTs_ and tissue segmentation.


.. _reconstruction_def:

Reconstruction
~~~~~~~~~~~~~~~~

The outputs from the :ref:`preprocessing_def` pipelines can be reconstructed in many other
software packages. We provide a curated set of :ref:`recon_workflows` in ``qsiprep``
that can run ODF/FOD reconstruction, tractography, Fixel estimation and regional
connectivity.



Note
------

The ``qsiprep`` pipeline uses much of the code from ``FMRIPREP``. It is critical
to note that the similarities in the code **do not imply that the authors of
FMRIPREP in any way endorse or support this code or its pipelines**.
