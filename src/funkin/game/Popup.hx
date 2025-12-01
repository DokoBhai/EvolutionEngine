package funkin.game;

import flixel.system.FlxAssets.FlxGraphicAsset;

class Popup extends FlxSprite
{
    static var popups:Array<Popup> = [];

    public function new(X:Float, Y:Float, Graphic:FlxGraphicAsset) {
        super(X, Y, Graphic);
    }

    public function pop(startDelay:Float = 0.5, kill:Bool = true) {
        velocity.y -= FlxG.random.float(220, 240);
        acceleration.y = 320;

        FlxTween.tween(this, {alpha: 0}, 1, {
            ease: FlxEase.quadIn,
            startDelay: startDelay,
            onComplete: twn -> {
                FlxG.state.remove(this);
                if (kill)
                    this.kill();
            }
        });
    }

    public static function recycle(X:Float = 0, Y:Float = 0, ?Graphic:FlxGraphicAsset):Popup {
        var popup = getAvaiablePopup();
        if (popup != null) {
            popup.setPosition(X, Y);
            popup.loadGraphic(Graphic);
            popup.scale.set(1, 1);
            popup.updateHitbox();
            popup.velocity.set(0, 0);
            popup.acceleration.set(0, 0);
            popup.angularAcceleration = 0;
            popup.angle = 0;
            popup.alpha = 1;
            popup.revive();

            return popup;
        }
        popup = new Popup(X, Y, Graphic);
        popups.push(popup);
        return popup;
    }

    public static function getAvaiablePopup():Null<Popup> {
        for (popup in popups) {
            if (!popup.alive)
                return popup;
        }
        return null;
    }
}