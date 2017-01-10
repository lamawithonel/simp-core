SIMP 6.0.0-Alpha
================

.. raw:: pdf

  PageBreak

.. contents::
  :depth: 2

.. raw:: pdf

  PageBreak


This release is known to work with:

  * RHEL 7.2 x86_64
  * CentOS 7.0 1511 x86_64

Breaking Changes
----------------

.. WARNING::
  This is an Alpha Release, things will either be broken, or break later!

At this time, the included codebase is stable with the feature set in the
**legacy** code from the `5.X` series.

However, we will be making additional updates and breaking changes to various
modules to take advantage of the breaking change of SIMP 6 itself.

If you try this version, please do `file bugs`_!

.. NOTE::
  If you are working to integrate SIMP into Puppet Enterprise, these are the
  modules that you need to use since they are Puppet 4 compatible.

Paths
^^^^^

Puppet AIO Paths
''''''''''''''''

The system has been updated to use the Puppet AIO paths. Please see the
`Puppet Location Reference`_ for full details.

SIMP Installation Paths
'''''''''''''''''''''''

For better integration with `r10k`_ and `Puppet Code Manager`_, SIMP now installs all
materials in ``/usr/share/simp`` by default.

A script ``simp_rpm_helper`` has been added to copy the ``environment`` and
`module` data into place at ``/etc/puppetlabs/code`` **if configured to do so**.

On the ISO, this configuration is done by default and will be set to
auto-update for all future RPM updates. If you wish to disable this behavior,
you should edit the options in ``/etc/simp/adapter_config.yaml``.

.. NOTE::
   Anything that is in a Git or Subversion repository in the `simp` environment
   will **not** be overwritten by ``simp_rpm_helper``.

Significant Updates
-------------------

API Changes
^^^^^^^^^^^

Quite a few modules have had changes that make them incompatible with the
Legacy SIMP stack.

We've attempted to capture those changes here at a high level so that you know
where you are going to need to focus to validate your Hiera data, ENC hooks,
and parameterized class calls.

pupmod-simp-simpcat
"""""""""""""""""""

To deconflict with the upstream ``puppetlabs-concat`` module, the ``simpcat``
**functions** were renamed to be prefaced by ``simpcat`` instead of ``concat``.

A simple find and replace of ``concat_fragment`` and ``concat_build`` in legacy
code with ``simpcat_fragment`` and ``simpcat_build`` should suffice. Be sure to
check for ``Concat_fragment`` and ``Concat_build`` resource dependencies!

pupmod-simp-pupmod
""""""""""""""""""

This module has code that only works with Puppet 4

pupmod-simp-foreman
"""""""""""""""""""

The Foreman module has been removed until it works consistently with Puppet 4

Puppet AIO
^^^^^^^^^^

The latest version of the Puppet AIO stack has been included, along with an
updated Puppet Server and PuppetDB.

simp-extras
^^^^^^^^^^^

The main ``simp`` RPM has been split to move the lesser-used portions of the
SIMP infrastructure into a ``simp-extras`` RPM. This RPM will grow as more of
the non-essential portions are identified and isolated.

The goal of this RPM is to keep the SIMP core version churn to a minimum while
allowing the ecosystem around the SIMP core to grow and flourish as time
progresses.

Security Announcements
----------------------

RPM Updates
-----------

+---------------------+-------------+-------------+
| Package             | Old Version | New Version |
+=====================+=============+=============+
| puppet-agent        | N/A         | 1.6.2-1     |
+---------------------+-------------+-------------+
| puppet-client-tools | N/A         | 1.1.0-1     |
+---------------------+-------------+-------------+
| puppetdb            | 2.3.8-1     | 4.2.2-1     |
+---------------------+-------------+-------------+
| puppetdb-termini    | N/A         | 4.2.2-1     |
+---------------------+-------------+-------------+
| puppetdb-terminus   | 2.3.8-1     | N/A         |
+---------------------+-------------+-------------+
| puppetserver        | 1.1.1-1     | 2.6.0-1     |
+---------------------+-------------+-------------+

Fixed Bugs
----------

New Features
------------

Known Bugs
----------

.. _file bugs: https://simp-project.atlassian.net
.. _Puppet_Location_Reference: https://docs.puppet.com/puppet/4.7/reference/whered_it_go.html#where-did-everything-go-in-puppet-4.x
.. _r10k: https://github.com/puppetlabs/r10k
.. _Puppet Code Manager: https://docs.puppet.com/pe/latest/code_mgr.html
