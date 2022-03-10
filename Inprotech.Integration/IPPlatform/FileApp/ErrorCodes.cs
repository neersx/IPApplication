namespace Inprotech.Integration.IPPlatform.FileApp
{
    public static class ErrorCodes
    {
        public const string RequirementsUnmet = "requirements-unmet";

        public const string InvalidCaseForFiling = "invalid-case-for-filing";

        public const string CaseAlreadyFiled = "case-already-filed";

        public const string UnableToAccessFile = "unable-to-access-file";

        public const string IneligibleFileAgent = "ineligible-file-agent-selected";

        public const string MissingPctIntlApplicationNo = "PCT-case-missing-application-number";

        public const string MissingPctIntlApplicationDate = "PCT-case-missing-application-date";

        public const string MissingPriorityNo = "Priority-case-missing-priority-number";

        public const string MissingPriorityDate = "Priority-case-missing-priority-date";

        public const string MissingPriorityCountry = "Priority-case-missing-priority-country";

        public const string MissingFilingLanguage = "Priority-case-missing-filing-language";

        public const string MissingTitle = "Priority-case-missing-title";

        public const string PassedPriorityDeadline = "Priority-deadline-date-has-passed";

        public const string CaseNotInFile = "case-not-available-in-file";

        public const string IncorrectFileUrl = "incorrect-file-url";

        public const string MissingPctApplicantName = "PCT-case-missing-applicant-name";

        public const string MissingPriorityApplicantName = "Priority-case-missing-applicant-name";

        public const string MissingClasses = "priority-case-missing-classes";

        public const string IncompleteClasses = "priority-case-incomplete-classes";

        public const string MissingClassTextLanguage = "priority-case-missing-language";

        public const string CaseCountryClassMismatchByCountry = "priority-case-country-class-mismatch-by-country";

        public const string CaseCountryClassMismatchByClassCode = "priority-case-country-class-mismatch-by-class-code";

        public const string TrademarkImageNotSupported = "trademark-image-unsupported";
    }
}