using System;
using System.Linq;
using System.Text;
using InprotechKaizen.Model.Components.Names.Extensions;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Names
{

    public static class NameExtensions
    {
        public static DebtorStatus GetRestriction(this Name name, IDbContext context)
        {
            if (name == null) throw new ArgumentNullException("name");
            if (context == null) throw new ArgumentNullException("context");

            var clientDetail = context.Set<ClientDetail>()
                                      .FirstOrDefault(c => c.Id == name.Id);

            return clientDetail?.DebtorStatus;
        }

        public static bool IsActive(this Name name, Func<DateTime> systemClock)
        {
            if (name == null) throw new ArgumentNullException("name");
            if (systemClock == null) throw new ArgumentNullException("systemClock");

            return name.DateCeased == null || name.DateCeased > systemClock().Date;
        }

        public static string Formatted(this Name name, NameStyles? nameStyle = null, NameStyles? fallbackNameStyle = null)
        {
            if (name == null) throw new ArgumentNullException(nameof(name));

            var defaultNameStyle = fallbackNameStyle ?? NameStyles.Default;

            var effectiveNameStyle = nameStyle ?? ((NameStyles?)name.NameStyle ?? (NameStyles?)name.Nationality?.NameStyleId ?? defaultNameStyle);

            return FormattedName.For(name.LastName, name.FirstName, name.Title, name.MiddleName, name.Suffix, effectiveNameStyle);
        }

        public static string FormattedWithDefaultStyle(this Name name)
        {
            if (name == null) throw new ArgumentNullException(nameof(name));

            return FormattedName.For(name.LastName, name.FirstName, name.Title, name.MiddleName, null);
        }

        public static string FormattedNameOrNull(this Name name, NameStyles nameStyle = NameStyles.Default, NameStyles? fallbackNameStyle = null)
        {
            return name?.Formatted(nameStyle, fallbackNameStyle);
        }

        public static Address PostalAddress(this Name name)
        {
            if (name == null) throw new ArgumentNullException(nameof(name));

            if (!name.Addresses.Any()) return null;

            var nameAddress = name.Addresses.SingleOrDefault(a =>
                a.AddressId == name.PostalAddressId &&
                a.AddressType == (int)AddressType.Postal);

            return nameAddress?.Address;
        }

        public static Address StreetAddress(this Name name)
        {
            if (name == null) throw new ArgumentNullException(nameof(name));

            if (!name.Addresses.Any()) return null;

            var nameAddress = name.Addresses.SingleOrDefault(a =>
                a.AddressId == name.StreetAddressId &&
                a.AddressType == (int)AddressType.Street);

            return nameAddress?.Address;
        }

        public static Telecommunication MainEmail(this Name name)
        {
            if (name == null) throw new ArgumentNullException(nameof(name));

            if (!name.Telecoms.Any()) return null;

            var email = name.Telecoms.SingleOrDefault(a =>
                a.TeleCode == name.MainEmailId);

            return email?.Telecommunication;
        }

        public static string MainEmailAddress(this Name name)
        {
            return name.MainEmail()?.TelecomNumber;
        }

        public static Telecommunication MainPhone(this Name name)
        {
            if (name == null) throw new ArgumentNullException(nameof(name));

            if (!name.Telecoms.Any()) return null;

            var phone = name.Telecoms.SingleOrDefault(a =>
                a.TeleCode == name.MainPhoneId);

            return phone?.Telecommunication;
        }

        public static string OtherPhones(this Name name)
        {
            if (name == null) throw new ArgumentNullException(nameof(name));

            if (!name.Telecoms.Any()) return null;

            var phone = name.Telecoms.Where(a => a.TeleCode != name.MainPhoneId);

            StringBuilder telephoneNumbers = new StringBuilder();

            foreach (var tel in phone)
            {
                if (tel.Telecommunication?.TelecomType?.Name == KnownTelecomTypes.Telephone.ToString())
                {
                    if (name.MainPhoneId.HasValue)
                    {
                        telephoneNumbers.Append(", " + tel.Telecommunication.Formatted());
                    }
                    else
                    {
                        telephoneNumbers.Append(tel.Telecommunication.Formatted() + ", ");
                    }

                }
            }

            return telephoneNumbers.ToString().TrimEnd(' ').TrimEnd(',');
        }

        public static Telecommunication MainFax(this Name name)
        {
            if (name == null) throw new ArgumentNullException(nameof(name));

            if (!name.Telecoms.Any()) return null;

            var fax = name.Telecoms.SingleOrDefault(a =>
                a.TeleCode == name.MainFaxId);

            return fax?.Telecommunication;
        }
    }
}