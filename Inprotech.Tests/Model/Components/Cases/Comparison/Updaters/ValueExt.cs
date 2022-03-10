using InprotechKaizen.Model.Components.Cases.Comparison.Results;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.Updaters
{
    public static class ValueExt
    {
        public static Value<T> AsUpdatedValue<T>(this Value<T> v, T ourValue, T theirValue)
        {
            v.OurValue = ourValue;
            v.TheirValue = theirValue;
            v.Different = true;
            v.Updateable = true;
            v.Updated = true;

            return v;
        }

        public static Value<T> AsNonUpdatedValue<T>(this Value<T> v, T ourValue, T theirValue)
        {
            v.OurValue = ourValue;
            v.TheirValue = theirValue;
            v.Different = true;
            v.Updateable = true;
            v.Updated = false;

            return v;
        }
    }
}