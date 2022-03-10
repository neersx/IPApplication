using System;

namespace Inprotech.Contracts
{
    public interface ITimeZoneService
    {
        bool TryConvertTimeFromUtc(DateTime dateTime, string timeZoneId, out DateTime output);
    }
}