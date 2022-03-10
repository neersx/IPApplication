using System;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks;
using InprotechKaizen.Model;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Model
{
    public static class MatchingFieldDataExtension
    {
        const string SuccessMessage = "VERIFICATION_SUCCESS";
        const string FailureMessage = "VERIFICATION_FAILURE";

        public static string GetPublicValue(this MatchingFieldData data)
        {
            return data == null ? string.Empty : data.PublicData;
        }

        public static string GetInputValue(this MatchingFieldData data)
        {
            return data == null ? string.Empty : data.Input;
        }

        public static bool IsVerified(this MatchingFieldData data, string propertyType = KnownPropertyTypes.Patent)
        {
            if (propertyType == KnownPropertyTypes.TradeMark)
            {
                return data != null && data.StatusCode != TrademarkValidationStatusCodes.PublicDataNotMatchesUserData
                                        && data.StatusCode != TrademarkValidationStatusCodes.UserDataNotProvided;
            }

            return data != null && (data.Message.Equals(SuccessMessage, StringComparison.InvariantCulture)
                                    || string.IsNullOrWhiteSpace(data.Input + data.PublicData) && data.Message.Equals(FailureMessage, StringComparison.InvariantCulture));
        }

        public static bool IsNotVerified(this MatchingFieldData data, string propertyType = KnownPropertyTypes.Patent)
        {
            if (propertyType == KnownPropertyTypes.TradeMark)
            {
                return data.StatusCode.Equals(TrademarkValidationStatusCodes.UserDataNotProvided)
                       || data.StatusCode.Equals(TrademarkValidationStatusCodes.PublicDataNotMatchesUserData);
            }

            return !string.IsNullOrEmpty(data.Message) && data.Message.Equals(FailureMessage, StringComparison.InvariantCulture)
                                     && !string.IsNullOrWhiteSpace(data.Input + data.PublicData);
        }

        public static string StatusText(this MatchingFieldData data, string memberName)
        {
            return $"{memberName}:{data.Message}";
        }

        public static bool IsEmpty(this MatchingFieldData data)
        {
            return data == null || data.StatusCode == "11";  // both sides empty.
        }
    }
}