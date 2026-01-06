package funkin.backend;

import flixel.input.keyboard.FlxKey;

class Preferences {
    public static var keyBinds:Map<String, Array<FlxKey>> = [
        'note_left'  => [ A, LEFT  ],
        'note_down'  => [ S, DOWN  ],
        'note_up'    => [ K, UP    ],
        'note_right' => [ L, RIGHT ]
    ];
}