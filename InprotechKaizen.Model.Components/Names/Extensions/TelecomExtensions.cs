using System;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Components.Names.Extensions
{
    public static class TelecomExtensions
    {
        public static string FormattedOrNull(this Telecommunication telecom)
        {
            return telecom == null ? null : Formatted(telecom);
        }

        public static string Formatted(this Telecommunication telecom)
        {
            if (telecom == null) throw new ArgumentNullException(nameof(telecom));

            return FormattedTelecom.For(telecom.Isd, telecom.AreaCode, telecom.TelecomNumber, telecom.Extension);
        }
    }
}