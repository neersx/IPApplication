using System;
using System.Collections.Generic;

namespace Inprotech.Infrastructure.Extensions
{
    public sealed class LambdaEqualityComparer<T> : IEqualityComparer<T>
    {
        private readonly Func<T, T, bool> _equalsFunc;
        private readonly Func<T, int> _getHashCodeFunc;

        public LambdaEqualityComparer(Func<T, T, bool> equalsFunc, Func<T, int> getHashCodeFunc)
        {
            _equalsFunc = equalsFunc;
            _getHashCodeFunc = getHashCodeFunc;
        }

        public bool Equals(T x, T y)
        {
            return _equalsFunc(x, y);
        }

        public int GetHashCode(T obj)
        {
            return _getHashCodeFunc(obj);
        }
    }
}
