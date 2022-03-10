using System;
using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Results
{
    public class Value<T>
    {
        public T OurValue { get; set; }
        public T TheirValue { get; set; }
        public string TheirDescription { get; set; }
        public bool? Different { get; set; }
        public bool? Updateable { get; set; }
        public bool Updated { get; set; }
    }

    public static class ValueExt
    {
        static bool IsApplicable<T>(this Value<T> v)
        {
            if (v.Different.GetValueOrDefault()) 
                return true;

            if (v.Updateable.GetValueOrDefault())
                return true;

            if ( EqualityComparer<T>.Default.Equals(v.OurValue, default(T)) &&
                EqualityComparer<T>.Default.Equals(v.TheirValue, default(T)))
            {
                // both sides null, not applicable.
                return false;
            }

            return true;
        }

        public static Value<T> ReturnsIfApplicable<T>(this Value<T> value)
        {
            if (value == null) throw new ArgumentNullException("value");
            
            return value.IsApplicable()
                ? value
                : null;
        }

        public static T UpdatedOrDefault<T>(this Value<T> value, T defaultValue)
        {
            if (value != null && value.IsApplicable() && value.Updated)
            {
                return value.TheirValue;
            }
            return defaultValue;
        }

        public static T ApplyIfApplicable<T>(this Value<T> value)
        {
            return UpdatedOrDefault(value, default(T));
        }
    }
}