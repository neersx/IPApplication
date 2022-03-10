using System;
using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Names
{
    public enum NameStyles
    {
        Default = -1,
        FirstNameThenFamilyName = 7101,
        FamilyNameThenFirstNames = 7102
    }

    public static class FormattedName
    {
        const string Space = " ";
        const string Comma = ", ";
        const string Empty = "";

        static readonly Dictionary<NameStyles, Func<string, string, string, string, string, string>> _ = new Dictionary
            <NameStyles, Func<string, string, string, string, string, string>>
        {
            {NameStyles.Default, DefaultFormat},
            {NameStyles.FamilyNameThenFirstNames, FamilyNameThenFirstName},
            {NameStyles.FirstNameThenFamilyName, FirstNameThenFamilyName}
        };

        public static string For(string name, string firstName, NameStyles nameStyle = NameStyles.Default)
        {
            var formattedName = _[nameStyle](name, firstName, null, null, null);
            return string.IsNullOrWhiteSpace(formattedName) ? null : formattedName;
        }

        public static string For(string name, string firstName, string title, string middleName, string suffix,
            NameStyles nameStyle = NameStyles.Default)
        {
            var formattedName = _[nameStyle](name, firstName, title, middleName, suffix);
            return string.IsNullOrWhiteSpace(formattedName) ? null : formattedName;
        }

        static string DefaultFormat(string name, string firstName, string title, string middleName, string suffix)
        {
            return (name ?? Empty) +
                   (!string.IsNullOrWhiteSpace(suffix) ? Space + suffix : Empty) +
                   (!string.IsNullOrWhiteSpace(firstName) ? Comma + firstName : Empty) +
                   (!string.IsNullOrWhiteSpace(middleName) ? Space + middleName : Empty);
        }

        static string FirstNameThenFamilyName(string name, string firstName, string title, string middleName,
            string suffix)
        {
            return (!string.IsNullOrWhiteSpace(title) ? title + Space : Empty) +
                   (!string.IsNullOrWhiteSpace(firstName) ? firstName + Space : Empty) +
                   (!string.IsNullOrWhiteSpace(middleName) ? middleName + Space : Empty) +
                   name +
                   (!string.IsNullOrWhiteSpace(suffix) ? Space + suffix : Empty);
        }

        static string FamilyNameThenFirstName(string name, string firstName, string title, string middleName,
            string suffix)
        {
            return (name ?? Empty) +
                   (!string.IsNullOrWhiteSpace(suffix) ? Space + suffix : Empty) +
                   (!string.IsNullOrWhiteSpace(firstName) ? Space + firstName : Empty) +
                   (!string.IsNullOrWhiteSpace(middleName) ? Space + middleName : Empty) +
                   (!string.IsNullOrWhiteSpace(title) ? Space + title : Empty);
        }

        public static NameStyles EffectiveNameStyle(int? nameStyle, int? nationalityNameStyle, NameStyles fallbackNameStyle)
        {
            var dataNameStyle = nameStyle ?? nationalityNameStyle;
            return dataNameStyle != null
                ? (NameStyles) dataNameStyle
                : fallbackNameStyle;
        }
    }
}