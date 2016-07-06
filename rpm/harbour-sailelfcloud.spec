# 
# Do NOT Edit the Auto-generated Part!
# Generated by: spectacle version 0.27
# 

Name:       harbour-sailelfcloud

# >> macros
# << macros

%{!?qtc_qmake:%define qtc_qmake %qmake}
%{!?qtc_qmake5:%define qtc_qmake5 %qmake5}
%{!?qtc_make:%define qtc_make make}
%{?qtc_builddir:%define _builddir %qtc_builddir}
Summary:    Sailfish elfCLOUD client
Version:    2.0
Release:    1
Group:      Qt/Qt
License:    LICENSE
URL:        https://github.com/TeemuAhola/sailelfcloud
Source0:    %{name}-%{version}.tar.bz2
Source100:  harbour-sailelfcloud.yaml
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   pyotherside-qml-plugin-python3-qt5 >= 1.3
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  desktop-file-utils

%description
Sailfish client for elfCLOUD cloud storage access. See https://secure.elfcloud.fi/fi_FI/.


%package test
Summary:    Tests for Sailfish client for elfCLOUD
Group:      Qt/Qt
Requires:   %{name} = %{version}-%{release}
Requires:   qt5-qtdeclarative-import-qttest
BuildRequires:  pkgconfig(Qt5QuickTest)

%description test
Tests package for Sailfish client for elfCLOUD

%prep
%setup -q -n %{name}-%{version}

# >> setup
# << setup

%build
# >> build pre
# << build pre

%qtc_qmake5  \
    VERSION=%{version} \
    RELEASE=%{release}

%qtc_make %{?_smp_mflags}

# >> build post
# << build post

%install
rm -rf %{buildroot}
# >> install pre
# << install pre
%qmake5_install

# >> install post
# << install post

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_datadir}/applications
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
%{_datadir}/%{name}/qml
%{_datadir}/%{name}/translations/*.qm
%{_datadir}/%{name}/lib/*.egg
%{_bindir}/%{name}
# >> files
# << files

%files test
%defattr(-,root,root,-)
%{_bindir}/tst-%{name}
%{_datadir}/tst-%{name}/*.qml
%{_datadir}/tst-%{name}/*.sh
# >> files test
# << files test
