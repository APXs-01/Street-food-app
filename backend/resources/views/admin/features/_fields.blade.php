<label for="label">Label</label>
<input id="label" type="text" name="label" value="{{ old('label', $flag?->label) }}" required maxlength="120" placeholder="Vendor analytics">

<label for="description">Description (optional)</label>
<input id="description" type="text" name="description" value="{{ old('description', $flag?->description) }}" maxlength="255" placeholder="What turning this on does in the app">

<input type="hidden" name="enabled" value="0">
<label class="check">
    <input type="checkbox" name="enabled" value="1" @checked((bool) old('enabled', $flag?->enabled ?? false))>
    Enabled
</label>
