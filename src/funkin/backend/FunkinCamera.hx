package funkin.backend;

@:access(flixel.FlxCamera)
class FunkinCamera extends FlxCamera {
    public var defaultCamZoom:Float = 1;
    public var lerpFactor:Float = 0.082;
    public var lerpEnabled:Bool = true;
    public var zoomBounds:Float = 4;

    public function new() super();

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (lerpEnabled)
            zoom = FlxMath.lerp(zoom, defaultCamZoom, getLerpRatio(lerpFactor, elapsed));

        zoom = FlxMath.bound(zoom, -zoomBounds, zoomBounds);
    }
}