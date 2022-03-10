using System;
using System.Collections.Generic;
using System.Linq;

namespace InprotechKaizen.Model.Persistence
{
    public class Delta<T> : ICloneable
    {
        public ICollection<T> Added;
        public ICollection<T> Deleted;
        public ICollection<T> Updated;

        public Delta()
        {
            Added = new List<T>();
            Updated = new List<T>();
            Deleted = new List<T>();
        }

        public object Clone()
        {
            var valueType = typeof(T).IsValueType;
            var cloneable = typeof(ICloneable).IsAssignableFrom(typeof(T));

            if (!valueType && !cloneable) throw new InvalidOperationException("Delta must either be cloneable or it is a value type to avoid shared references to be overridden accidentally.");

            if (cloneable)
            {
                return new Delta<T>
                {
                    Added = Added.Select(_ => (T)((ICloneable)_).Clone()).ToArray(),
                    Updated = Updated.Select(_ => (T)((ICloneable)_).Clone()).ToArray(),
                    Deleted = Deleted.Select(_ => (T)((ICloneable)_).Clone()).ToArray()
                };
            }

            return new Delta<T>
            {
                Added = Added.ToArray(),
                Updated = Updated.ToArray(),
                Deleted = Deleted.ToArray()
            };
        }

        public IEnumerable<T> AllDeltas()
        {
            return Added.Union(Updated).Union(Deleted);
        }

        public IEnumerable<T> AllUpdatedAndDeletedDeltas()
        {
            return Updated.Union(Deleted);
        }
    }
}