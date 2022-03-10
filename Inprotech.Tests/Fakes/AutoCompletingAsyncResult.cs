using System;
using System.Threading;

namespace Inprotech.Tests.Fakes
{
    public class AutoCompletingAsyncResult : IAsyncResult
    {
        public AutoCompletingAsyncResult(AsyncCallback callback, object state)
        {
            AsyncState = state;
            IsCompleted = true;
            callback(this);
        }

        public bool IsCompleted { get; }

        public WaitHandle AsyncWaitHandle => throw new NotSupportedException();

        public object AsyncState { get; }
        public bool CompletedSynchronously { get; private set; }
    }
}