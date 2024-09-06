#!/usr/bin/env python
#
# STATEMENT OF CHANGES: This file is derived from sources licensed under the Apache-2.0 terms,
# and uses the following portion of the original code:
# https://github.com/nipreps/fmriprep/blob/fe7c9ff8731635d7f25749f2afd99eb77d26305d/scripts/
# fetch_templates.py#L10-L136
#
# ORIGINAL WORK'S ATTRIBUTION NOTICE:
#
#     Copyright The NiPreps Developers <nipreps@gmail.com>
#
#     Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.
#
#     We support and encourage derived works from this project, please read
#     about our expectations at
#
#         https://www.nipreps.org/community/licensing/
"""
Standalone script to facilitate caching of required TemplateFlow templates.

To download and view how to use this script, run the following commands inside a terminal:
1. wget https://raw.githubusercontent.com/pennlinc/qsirecon_build/main/scripts/fetch_templates.py
2. python fetch_templates.py -h
"""

import argparse
import os


def fetch_MNI2009():
    """
    Expected templates:

    tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_T1w.nii.gz
    tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-02_T1w.nii.gz
    tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_desc-brain_mask.nii.gz
    tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-02_desc-brain_mask.nii.gz
    tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_desc-carpet_dseg.nii.gz
    tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_label-brain_probseg.nii.gz
    """
    template = "MNI152NLin2009cAsym"

    tf.get(template, resolution=(1, 2), desc=None, suffix="T1w")
    tf.get(template, resolution=(1, 2), desc="brain", suffix="mask")
    tf.get(template, resolution=1, atlas=None, desc="carpet", suffix="dseg")
    tf.get(template, resolution=1, label="brain", suffix="probseg")


def fetch_MNIInfant(cohort=2):
    """
    Expected templates:

    tpl-MNIInfant/cohort-2/tpl-MNIInfant_cohort-2_res-1_T1w.nii.gz
    tpl-MNIInfant/cohort-2/tpl-MNIInfant_cohort-2_res-1_T2w.nii.gz
    tpl-MNIInfant/cohort-2/tpl-MNIInfant_cohort-2_res-1_desc-brain_mask.nii.gz
    tpl-MNIInfant/cohort-2/tpl-MNIInfant_cohort-2_res-2_T1w.nii.gz
    tpl-MNIInfant/cohort-2/tpl-MNIInfant_cohort-2_res-2_T1w.nii.gz
    tpl-MNIInfant/cohort-2/tpl-MNIInfant_cohort-2_res-2_desc-brain_mask.nii.gz
    """
    template = "MNIInfant"

    tf.get(template, cohort=cohort, suffix="T1w")
    tf.get(template, cohort=cohort, suffix="T2w")
    tf.get(template, cohort=cohort, desc="brain", suffix="mask")


def fetch_all():
    fetch_MNI2009()
    fetch_MNIInfant()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Helper script for pre-caching required templates to run QSIRecon",
    )
    parser.add_argument(
        "--tf-dir",
        type=os.path.abspath,
        help="Directory to save templates in. If not provided, templates will be saved to"
        " `${HOME}/.cache/templateflow`.",
    )
    opts = parser.parse_args()

    # set envvar (if necessary) prior to templateflow import
    if opts.tf_dir is not None:
        os.environ["TEMPLATEFLOW_HOME"] = opts.tf_dir

    import templateflow.api as tf

    fetch_all()
