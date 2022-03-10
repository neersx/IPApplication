using Inprotech.Integration.ExternalApplications.Crm.Request;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Integration.ExternalApplications.Crm
{
    public interface ICrmContactProcessor
    {
        Name CreateContactName(Contact crmContact);
    }

    public class CrmContactProcessor : ICrmContactProcessor
    {
        readonly IDbContext _dbContext;
        readonly INewNameProcessor _newNameProcessor;
        readonly Func<DateTime> _systemClock;
        readonly ITransactionRecordal _transactionRecordal;

        public CrmContactProcessor(IDbContext dbContext, INewNameProcessor newNameProcessor, ITransactionRecordal transactionRecordal,  Func<DateTime> systemClock)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (newNameProcessor == null) throw new ArgumentNullException("newNameProcessor");
            if (transactionRecordal == null) throw new ArgumentNullException("transactionRecordal");
            if (systemClock == null) throw new ArgumentNullException("systemClock");

            _dbContext = dbContext;
            _newNameProcessor = newNameProcessor;
            _transactionRecordal = transactionRecordal;
            _systemClock = systemClock;
        }

        public Name CreateContactName(Contact crmContact)
        {
            var contact = NewNameMapper(crmContact);

            using (var tx = _dbContext.BeginTransaction())
            {
                var newName = _newNameProcessor.InsertName(contact);

                _newNameProcessor.InsertIndividual(newName.Id, contact);

                foreach (var telecom in from nameTelecom in contact.NameTeleCommunications
                                        let telecom = _newNameProcessor.InsertNameTelecom(newName.Id, nameTelecom)
                                        where nameTelecom.IsMainTelecom
                                        select telecom)
                {
                    switch (telecom.TelecomType.TableTypeId)
                    {
                        case (int)KnownTelecomTypes.Telephone:
                            newName.MainPhoneId = telecom.Id;
                            break;
                        case (int)KnownTelecomTypes.Email:
                            newName.MainEmailId = telecom.Id;
                            break;
                        case (int)KnownTelecomTypes.Fax:
                            newName.MainFaxId = telecom.Id;
                            break;
                    }
                }

                foreach (var address in from nameAddress in contact.NameAddresses
                                        let address = _newNameProcessor.InsertNameAddress(newName.Id, nameAddress)
                                        where nameAddress.IsMainAddress
                                        select address)
                {
                    switch (address.AddressType)
                    {
                        case (int)KnownAddressTypes.PostalAddress:
                            newName.PostalAddressId = address.AddressId;
                            break;
                        case (int)KnownAddressTypes.StreetAddress:
                            newName.StreetAddressId = address.AddressId;
                            break;
                    }
                }

                _newNameProcessor.InsertNameTypeClassification(newName, new List<string> { KnownNameTypes.Contact });

                newName.DateChanged = _systemClock().Date;

                _transactionRecordal.RecordTransactionFor(newName, NameTransactionMessageIdentifier.NewName);

                _dbContext.SaveChanges();

                tx.Complete();

                return newName;
            }
        }

        NewName NewNameMapper(Contact contact)
        {
            var newName = new NewName
            {
                Name = contact.Surname,
                FirstName = contact.GivenName,
                HomeCountryCode = GetCountryCode(contact.HomeCountry),
                Individual = true,
                Staff = false,
                Client = false,
                Supplier = false,
                Title = IsValidTitle(contact.Title) ? contact.Title : null
            };

            newName = _newNameProcessor.GetNameDefaults(newName);
            newName.NameCode = _newNameProcessor.GenerateNameCode();

            contact.HomeCountry = newName.HomeCountryCode;
            newName.NameAddresses = AddressCollection(contact);
            newName.NameTeleCommunications = TeleComCollection(contact);

            return newName;
        }

        IEnumerable<NewNameAddress> AddressCollection(Contact contact)
        {
            var addressCollection = new List<NewNameAddress>();

            var address = new NewNameAddress
            {
                Owner = true,
                City = contact.MailingCity,
                StateCode = contact.MailingState,
                PostCode = contact.MailingPostalCode,
                CountryCode = GetCountryCode(contact.MailingCountry) ?? contact.HomeCountry,
                IsMainAddress = true
            };
            address.StateCode = GetStateCode(contact.MailingState, address.CountryCode);

            if (!string.IsNullOrEmpty(contact.MailingPostOfficeBox))
            {
                address.AddressTypeKey = (int)KnownAddressTypes.PostalAddress;
                address.Street = contact.MailingPostOfficeBox;
            }
            else
            {
                address.AddressTypeKey = (int)KnownAddressTypes.StreetAddress;
                address.Street = contact.MailingStreet;
            }

            addressCollection.Add(address);

            address = new NewNameAddress
            {
                Owner = true,
                City = contact.City,
                PostCode = contact.PostalCode,
                CountryCode = GetCountryCode(contact.Country) ?? contact.HomeCountry
            };
            address.StateCode = GetStateCode(contact.State, address.CountryCode);

            if (!string.IsNullOrEmpty(contact.PostOfficeBox))
            {
                address.AddressTypeKey = (int)KnownAddressTypes.PostalAddress;
                address.Street = contact.PostOfficeBox;
            }
            else
            {
                address.AddressTypeKey = (int)KnownAddressTypes.StreetAddress;
                address.Street = contact.Street;
            }
            addressCollection.Add(address);

            address = new NewNameAddress
            {
                Owner = true,
                City = contact.OtherCity,
                PostCode = contact.OtherPostalCode,
                CountryCode = GetCountryCode(contact.OtherCountry) ?? contact.HomeCountry
            };
            address.StateCode = GetStateCode(contact.OtherState, address.CountryCode);

            if (!string.IsNullOrEmpty(contact.OtherPostOfficeBox))
            {
                address.AddressTypeKey = (int)KnownAddressTypes.PostalAddress;
                address.Street = contact.OtherPostOfficeBox;
            }
            else
            {
                address.AddressTypeKey = (int)KnownAddressTypes.StreetAddress;
                address.Street = contact.OtherStreet;
            }
            addressCollection.Add(address);

            return addressCollection;
        }

        IEnumerable<NewNameTeleCommunication> TeleComCollection(Contact contact)
        {
            var teleComCollection = new List<NewNameTeleCommunication>();

            if (!string.IsNullOrEmpty(contact.Email))
            {
                var telecom = new NewNameTeleCommunication
                {
                    Owner = true,
                    IsMainTelecom = true,
                    TelecomTypeKey = (int)KnownTelecomTypes.Email,
                    TelecomNumber = contact.Email
                };
                teleComCollection.Add(telecom);
            }

            if (!string.IsNullOrEmpty(contact.Telephone))
            {
                var telecom = new NewNameTeleCommunication
                {
                    Owner = true,
                    IsMainTelecom = true,
                    TelecomTypeKey = (int)KnownTelecomTypes.Telephone,
                    TelecomNumber = contact.Telephone
                };
                teleComCollection.Add(telecom);
            }

            if (!string.IsNullOrEmpty(contact.Fax))
            {
                var telecom = new NewNameTeleCommunication
                {
                    Owner = true,
                    IsMainTelecom = true,
                    TelecomTypeKey = (int)KnownTelecomTypes.Fax,
                    TelecomNumber = contact.Fax
                };
                teleComCollection.Add(telecom);
            }

            return teleComCollection;
        }

        string GetCountryCode(string countryName)
        {
            if (string.IsNullOrEmpty(countryName))
                return null;
            var country = _dbContext.Set<Country>().FirstOrDefault(c => c.Id.Equals(countryName)) ??
                          _dbContext.Set<Country>().FirstOrDefault(c => c.Name.Contains(countryName));
            return country != null ? country.Id : null;
        }

        string GetStateCode(string stateName, string countryCode)
        {
            if (string.IsNullOrEmpty(stateName) || string.IsNullOrEmpty(countryCode))
                return null;
            var state = _dbContext.Set<State>().FirstOrDefault(c => c.Code.Equals(stateName) && c.CountryCode.Equals(countryCode)) ??
                          _dbContext.Set<State>().FirstOrDefault(c => c.Name.Contains(stateName) && c.CountryCode.Equals(countryCode));

            return state != null ? state.Code : null;
        }

        bool IsValidTitle(string title)
        {
            return _dbContext.Set<Titles>().Any(c => c.Title.Equals(title));
        }
        
    }
}