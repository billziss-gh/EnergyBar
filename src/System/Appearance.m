/**
 * @file Appearance.m
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

#import "Appearance.h"
#import "NSGlobalPreferenceTransition.h"

extern int SLSGetAppearanceThemeLegacy(void) __attribute__((weak_import));
extern void SLSSetAppearanceThemeLegacy(int) __attribute__((weak_import));
extern void SLSSetAppearanceThemeNotifying(int, int) __attribute__((weak_import));

Appearance GetAppearance(void)
{
    if (0 == SLSGetAppearanceThemeLegacy)
        return AppearanceLight;

    switch (SLSGetAppearanceThemeLegacy())
    {
    default:
    case 0:
        return AppearanceLight;
    case 1:
        return AppearanceDark;
    }
}

void SetAppearance(Appearance appearance)
{
    if (0 == SLSSetAppearanceThemeLegacy)
        return;

    int theme = 0;
    switch (appearance)
    {
    default:
    case AppearanceLight:
        theme = 0;
        break;
    case AppearanceDark:
        theme = 1;
        break;
    }

    Class cls = NSClassFromString(@"NSGlobalPreferenceTransition");
    id transition = [cls transition];
    SLSSetAppearanceThemeNotifying(theme, nil == transition);

    [transition postChangeNotification:0 completionHandler:^
    {
    }];
}
