using System;

namespace Inprotech.Integration.DmsIntegration.Component.iManage
{
    public static class KnownErrors
    {
        public const string ErrorInvalidSearchStringForCustom1And2Configuration =
            "CustomField1And2: Expected search string to be in the format 'xxxx.yyyy' but the given search string was '{0}'";

        public static readonly string CaseSearchFieldEmpty =
            string.Format(
                          @"The 'Case Search Field' is empty, this may result in an error. {0}
The value of 'Case Search Field' will be used to identify the case in the target DMS and is dependent on the field format specified, i.e. CustomField1, CustomField2, CustomField3 or CustomField1And2.  Specifically, CustomField1And2 must be in the form xxxx.yyyy",
                          Environment.NewLine);

        public static readonly string NameSearchFieldEmpty =
            string.Format(
                          @"The 'Name Search Field' is empty, this may result in an error. {0}
The value of 'Name Search Field' will be used to identify the name in the target DMS.  Name Code is typically used in the search.",
                          Environment.NewLine);
    }
}