using System;

namespace InprotechKaizen.Model.Persistence
{
    public interface ITransactionScope : IDisposable
    {
        void Complete();
    }
}