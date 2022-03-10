using System;
using System.Threading;

namespace Inprotech.Tests.Integration.Utils
{
    public static class Try
    {
        public static bool Do(Action action)
        {
            try
            {
                action();
                return true;
            }
            catch
            {
                return false;
            }
        }

        public static void Retry(int times, int wait, Action action)
        {
            for (int i = 0; i < times; i++)
            {
                try
                {
                    action();
                    return;
                }
                catch
                {
                    if (i == times - 1) throw;
                }

                Thread.Sleep(wait);
            }
        }

        public static bool Wait(int times, int wait, Func<bool> action)
        {
            for (int i = 0; i < times; i++)
            {
                try
                {
                    if (action()) return true;
                }
                catch
                {
                    if (i == times - 1) throw;
                }

                Thread.Sleep(wait);
            }

            return false;
        }
    }
}