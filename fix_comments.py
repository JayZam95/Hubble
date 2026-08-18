import os

# chat_background_view.dart
path1 = r'lib\features\chat\presentation\widgets\chat_background_view.dart'
with open(path1, 'r', encoding='utf-8') as f:
    text1 = f.read()

reps1 = [
    ("// 'dynamic_gradient', 'dynamic_image', 'custom_image' ", "/* 'dynamic_gradient', 'dynamic_image', 'custom_image' */ "),
    ("// Curated Unsplash HD URLs matching times of day for a beautiful aesthetic ", "/* Curated Unsplash HD URLs matching times of day for a beautiful aesthetic */ "),
    ("// Beach sunrise   ", "/* Beach sunrise */   "),
    ("// Sunny forest   ", "/* Sunny forest */   "),
    ("// Twilight sunset   ", "/* Twilight sunset */   "),
    ("// Starry night sky    ", "/* Starry night sky */    "),
    ("// Default: 'dynamic_gradient' (Smoothly shifting linear gradient)   ", "/* Default: 'dynamic_gradient' */   "),
    ("// Shift linear gradient endpoints based on animation   ", "/* Shift linear gradient endpoints based on animation */   "),
    ("// Slate Dark                       ", "/* Slate Dark */                       "),
    ("// Midnight Blue                       ", "/* Midnight Blue */                       "),
    ("// Neutral Black-Gray                     ]", "/* Neutral Black-Gray */                     ]"),
    ("// Bright Soft Slate                       ", "/* Bright Soft Slate */                       "),
    ("// Indigo tint                       ", "/* Indigo tint */                       "),
    ("// Pure Soft Gray                     ]", "/* Pure Soft Gray */                     ]")
]

for k, v in reps1:
    text1 = text1.replace(k, v)

with open(path1, 'w', encoding='utf-8') as f:
    f.write(text1)


# map_screen.dart
path2 = r'lib\features\marketplace\presentation\screens\map_screen.dart'
with open(path2, 'r', encoding='utf-8') as f:
    text2 = f.read()

reps2 = [
    ("// Center map on Lusaka, Zambia by default   ", "/* Center map on Lusaka, Zambia by default */   "),
    ("// Test if location services are enabled.     ", "/* Test if location services are enabled. */     "),
    ("// 1. Plot current user pulse marker if resolved and location shared         ", "/* 1. Plot current user pulse marker if resolved and location shared */         "),
    ("// 2. Plot active providers around current center         ", "/* 2. Plot active providers around current center */         "),
    ("// Render providers with a slight offset from the real location               ", "/* Render providers with a slight offset from the real location */               "),
    ("// The map pin \"tail\"                       ", "/* The map pin tail */                       "),
    ("// The circular profile picture                     ", "/* The circular profile picture */                     ")
]

for k, v in reps2:
    text2 = text2.replace(k, v)

with open(path2, 'w', encoding='utf-8') as f:
    f.write(text2)
