using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Integration.Exchange
{
    public static class KnownRequestStatus
    {
        static readonly Dictionary<short, string> Statuses = new Dictionary<short, string>
        {
            {0, "Ready"},
            {1, "Processing"},
            {2, "Failed"},
            {3, "Obsolete"}
        };

        public static string GetStatus(short key = 0)
        {
            if (!Statuses.TryGetValue(key, out var val))
            {
                val = string.Empty;
            }

            return val;
        }
    }

    public static class KnownRequestType
    {
        static readonly Dictionary<short, string> RequestTypes = new Dictionary<short, string>
        {
            {(short) ExchangeRequestType.Add, "Add"},
            {(short) ExchangeRequestType.Update, "Update"},
            {(short) ExchangeRequestType.Delete, "Delete"},
            {(short) ExchangeRequestType.Initialise, "Initialise"},
            {(short) ExchangeRequestType.SaveDraftEmail, "Email Draft"}
        };

        public static string GetType(short key = 0)
        {
            if (!RequestTypes.TryGetValue(key, out var val))
            {
                val = string.Empty;
            }

            return val;
        }
    }

    public enum ExchangeRequestStatus
    {
        Ready,
        Processing,
        Failed,
        Obsolete
    }

    public enum ExchangeRequestType : short
    {
        Add,
        Update,
        Delete,
        Initialise,
        SaveDraftEmail
    }
}