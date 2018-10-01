/**
 * @file Appearance.c
 *
 * @copyright 2018 Bill Zissimopoulos
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#include "Appearance.h"

extern int SLSGetAppearanceThemeLegacy(void) __attribute__((weak_import));
extern void SLSSetAppearanceThemeLegacy(int) __attribute__((weak_import));

Appearance GetAppearance(void)
{
    if (0 == SLSGetAppearanceThemeLegacy)
        return AppearanceAqua;

    switch (SLSGetAppearanceThemeLegacy())
    {
    default:
    case 0:
        return AppearanceAqua;
    case 1:
        return AppearanceDarkAqua;
    }
}

void SetAppearance(Appearance appearance)
{
    if (0 == SLSSetAppearanceThemeLegacy)
        return;

    switch (appearance)
    {
    default:
    case AppearanceAqua:
        SLSSetAppearanceThemeLegacy(0);
        break;
    case AppearanceDarkAqua:
        SLSSetAppearanceThemeLegacy(1);
        break;
    }
}
