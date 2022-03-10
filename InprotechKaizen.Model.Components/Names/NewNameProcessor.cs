using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Names
{
    public interface INewNameProcessor
    {
        Name InsertName(NewName name);

        void InsertIndividual(int nameKey, NewName name);

        Telecommunication InsertNameTelecom(int nameKey, NewNameTeleCommunication nameTelecom);

        NameAddress InsertNameAddress(int nameKey, NewNameAddress nameAddress);

        void InsertNameTypeClassification(Name newName, ICollection<string> selectedClassifications);

        NewName GetNameDefaults(NewName name);

        string GenerateNameCode();
    }

    public class NewNameProcessor : INewNameProcessor
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IDefaultNameTypeClassification _defaultNameTypeClassification;

        public NewNameProcessor(ISecurityContext securityContext, IDbContext dbContext, IDefaultNameTypeClassification defaultNameTypeClassification)
        {
            if (securityContext == null) throw new ArgumentNullException("securityContext");
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (defaultNameTypeClassification == null) throw new ArgumentNullException("defaultNameTypeClassification");

            _securityContext = securityContext;
            _dbContext = dbContext;
            _defaultNameTypeClassification = defaultNameTypeClassification;
        }

        public Name InsertName(NewName name)
        {
            if (name == null) throw new ArgumentNullException(nameof(name));

            var sqlCommand = _dbContext.CreateStoredProcedureCommand("naw_InsertName");

            var nameKeyParam = new SqlParameter("@pnNameKey", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            };

            sqlCommand.Parameters.AddRange(
                                           new[]
                                           {
                                               nameKeyParam,
                                               new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                               new SqlParameter("@psCulture", null), 
                                               new SqlParameter("@psNameCode", name.NameCode),
                                               new SqlParameter("@pbIsIndividual", name.Individual),
                                               new SqlParameter("@pbIsOrganisation", !name.Individual),
                                               new SqlParameter("@pbIsStaff", name.Staff),
                                               new SqlParameter("@pbIsClient", name.Client),
                                               new SqlParameter("@pbIsSupplier", name.Supplier),
                                               new SqlParameter("@psName", name.Name),
                                               new SqlParameter("@psTitle", name.Title),
                                               new SqlParameter("@psInitials", name.Initials),
                                               new SqlParameter("@psFirstName", name.FirstName),
                                               new SqlParameter("@psExtendedName", name.ExtendedName),
                                               new SqlParameter("@psSearchKey1", name.SearchKey1),
                                               new SqlParameter("@psSearchKey2", name.SearchKey2),
                                               new SqlParameter("@psNationalityCode", name.NationalityCode),
                                               new SqlParameter("@pdtDateCeased", null),
                                               new SqlParameter("@psRemarks", name.Remarks),
                                               new SqlParameter("@pnGroupKey", name.GroupKey),
                                               new SqlParameter("@pnNameStyleKey",name.NameStyleKey),
                                               new SqlParameter("@psInstructorPrefix", name.InstructorPrefix),
                                               new SqlParameter("@pnCaseSequence",name.CaseSequence),
                                               new SqlParameter("@psAirportCode",name.AirportCode),
                                               new SqlParameter("@psTaxNo",name.TaxNo),
                                               new SqlParameter("@pbIsNameCodeInUse",1),
                                               new SqlParameter("@pbIsIndividualInUse",1),
                                               new SqlParameter("@pbIsStaffInUse",1),
                                               new SqlParameter("@pbIsClientInUse",1),
                                               new SqlParameter("@pbIsSupplierInUse",1),
                                               new SqlParameter("@pbIsNameInUse",1),
                                               new SqlParameter("@pbIsTitleInUse",1),
                                               new SqlParameter("@pbIsInitialsInUse",1),
                                               new SqlParameter("@pbIsFirstNameInUse",1),
                                               new SqlParameter("@pbIsExtendedNameInUse",1),
                                               new SqlParameter("@pbIsSearchKey1InUse",1),
                                               new SqlParameter("@pbIsSearchKey2InUse",1),
                                               new SqlParameter("@pbIsNationalityCodeInUse",1),
                                               new SqlParameter("@pbIsDateCeasedInUse",1),
                                               new SqlParameter("@pbIsRemarksInUse",1),
                                               new SqlParameter("@pbIsGroupKeyInUse",1),
                                               new SqlParameter("@pbIsNameStyleKeyInUse",1),
                                               new SqlParameter("@pbIsInstructorPrefixInUse",1),
                                               new SqlParameter("@pbIsCaseSequenceInUse",1),
                                               new SqlParameter("@pbIsAirportCodeInUse",1),
                                               new SqlParameter("@pbIsTaxNoInUse",1),
                                               new SqlParameter("@pbCalledFromCentura", false)
                                           });

            sqlCommand.ExecuteNonQuery();
            var nameKey = (int)nameKeyParam.Value;
            return _dbContext.Set<Name>().Single(a => a.Id == nameKey);
        }

        public void InsertIndividual(int nameKey, NewName name)
        {
            if (name == null) throw new ArgumentNullException(nameof(name));

            var individual = new Individual(nameKey)
            {
                Gender = name.GenderCode,
                FormalSalutation = name.FormalSalutation,
                CasualSalutation = name.InformalSalutation
            };

            _dbContext.Set<Individual>().Add(individual);
        }

        public Telecommunication InsertNameTelecom(int nameKey, NewNameTeleCommunication nameTelecom)
        {
            if (nameTelecom == null) throw new ArgumentNullException(nameof(nameTelecom));

            var sqlCommand = _dbContext.CreateStoredProcedureCommand("naw_InsertNameTelecom");

            var telecomKeyParam = new SqlParameter("@pnTelecomKey", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            };

            sqlCommand.Parameters.AddRange(
                                           new[]
                                           {
                                               telecomKeyParam,
                                               new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                               new SqlParameter("@psCulture", null), 
                                               new SqlParameter("@pnNameKey", nameKey),
                                               new SqlParameter("@psTelecomNotes", nameTelecom.TelecomNotes),
                                               new SqlParameter("@pbIsOwner", nameTelecom.Owner),
                                               new SqlParameter("@pnTelecomTypeKey", nameTelecom.TelecomTypeKey),
                                               new SqlParameter("@psIsd", nameTelecom.Isd),
                                               new SqlParameter("@psAreaCode", nameTelecom.AreaCode),
                                               new SqlParameter("@psTelecomNumber", nameTelecom.TelecomNumber),
                                               new SqlParameter("@psExtension", nameTelecom.Extension),
                                               new SqlParameter("@pnCarrierKey", nameTelecom.CarrierKey),
                                               new SqlParameter("@pbIsReminderAddress", nameTelecom.ReminderAddress),
                                               new SqlParameter("@pbIsTelecomNotesInUse",1),
                                               new SqlParameter("@pbIsIsOwnerInUse",1),
                                               new SqlParameter("@pbIsTelecomTypeKeyInUse",1),
                                               new SqlParameter("@pbIsIsdInUse",1),
                                               new SqlParameter("@pbIsAreaCodeInUse",1),
                                               new SqlParameter("@pbIsTelecomNumberInUse",1),
                                               new SqlParameter("@pbIsExtensionInUse",1),
                                               new SqlParameter("@pbIsCarrierKeyInUse",1),
                                               new SqlParameter("@pbIsIsReminderAddressInUse",1),
                                               new SqlParameter("@pbCalledFromCentura", false)
                                           });

            sqlCommand.ExecuteNonQuery();
            var telecomKey = (int)telecomKeyParam.Value;
            return _dbContext.Set<Telecommunication>().Single(a => a.Id == telecomKey);
        }

        public NameAddress InsertNameAddress(int nameKey, NewNameAddress nameAddress)
        {
            if (nameAddress == null) throw new ArgumentNullException(nameof(nameAddress));

            var sqlCommand = _dbContext.CreateStoredProcedureCommand("naw_InsertNameAddress");

            var nameAddressKeyParam = new SqlParameter("@pnAddressKey", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            };

            sqlCommand.Parameters.AddRange(
                                           new[]
                                           {
                                               nameAddressKeyParam,
                                               new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                               new SqlParameter("@psCulture", null), 
                                               new SqlParameter("@pnNameKey", nameKey),
                                               new SqlParameter("@pnAddressTypeKey", nameAddress.AddressTypeKey),
                                               new SqlParameter("@pbIsOwner", nameAddress.Owner),
                                               new SqlParameter("@psCity", nameAddress.City),
                                               new SqlParameter("@psStreet", nameAddress.Street),
                                               new SqlParameter("@psStateCode", nameAddress.StateCode),
                                               new SqlParameter("@psPostCode", nameAddress.PostCode),
                                               new SqlParameter("@psCountryCode", nameAddress.CountryCode),
                                               new SqlParameter("@pnTelephoneKey", nameAddress.TelephoneKey),
                                               new SqlParameter("@pnFaxKey", nameAddress.FaxKey),
                                               new SqlParameter("@pnAddressStatusKey", nameAddress.AddressStatusKey),
                                               new SqlParameter("@pdtDateCeased", nameAddress.DateCeased),
                                               new SqlParameter("@pbIsIsOwnerInUse",1),
                                               new SqlParameter("@pbIsStreetInUse",1),
                                               new SqlParameter("@pbIsCityInUse",1),
                                               new SqlParameter("@pbIsStateCodeInUse",1),
                                               new SqlParameter("@pbIsPostCodeInUse",1),
                                               new SqlParameter("@pbIsCountryCodeInUse",1),
                                               new SqlParameter("@pbIsTelephoneKeyInUse",1),
                                               new SqlParameter("@pbIsFaxKeyInUse",1),
                                               new SqlParameter("@pbIsAddressStatusKeyInUse",1),
                                               new SqlParameter("@pbIsDateCeasedInUse",1),
                                               new SqlParameter("@pbCalledFromCentura", false)
                                           });

            sqlCommand.ExecuteNonQuery();
            var nameAddressKey = (int)nameAddressKeyParam.Value;
            return _dbContext.Set<NameAddress>().Single(a => a.AddressId == nameAddressKey);
        }

        public void InsertNameTypeClassification(Name newName, ICollection<string> selectedClassifications)
        {
            var defaultNameTypeClassificationList = _defaultNameTypeClassification.FetchNameTypeClassification(1).ToList();

            var validNameTypeClassification = defaultNameTypeClassificationList.Where(ntc => selectedClassifications.Contains(ntc.NameTypeKey));
            foreach (var ntc in validNameTypeClassification)
            {
                ntc.IsSelected = true;
            }

            foreach (var vntc in defaultNameTypeClassificationList)
            {
                var isAllowed = vntc.IsSelected ? 1 : 0;

                var ntc =
                    _dbContext.Set<NameTypeClassification>()
                        .FirstOrDefault(nt => nt.NameId == newName.Id && nt.NameTypeId == vntc.NameTypeKey);

                if (ntc != null)
                {
                    ntc.IsAllowed = isAllowed;
                }
                else
                {
                    var nameType = _dbContext.Set<NameType>().First(nt => nt.NameTypeCode == vntc.NameTypeKey);
                    ntc = new NameTypeClassification(newName, nameType) { IsAllowed = isAllowed };
                    _dbContext.Set<NameTypeClassification>().Add(ntc);
                    newName.NameTypeClassifications.Add(ntc);
                }
            }
        }

        public NewName GetNameDefaults(NewName name)
        {
            if (name == null) throw new ArgumentNullException(nameof(name));

            var sqlCommand = _dbContext.CreateStoredProcedureCommand("na_GetNameDefaults");

            var titleParam = new SqlParameter("@psTitle", SqlDbType.NVarChar, 20, ParameterDirection.InputOutput, 
                true, 0, 0, string.Empty, DataRowVersion.Default, name.Title);
            var countryParam = new SqlParameter("@psCountryCode", SqlDbType.NVarChar, 3, ParameterDirection.InputOutput,
                true, 0, 0, string.Empty, DataRowVersion.Default, name.HomeCountryCode);
            var genderCodeParam = new SqlParameter("@psGenderCode", SqlDbType.NChar, 1, ParameterDirection.InputOutput, true,
                0, 0, string.Empty, DataRowVersion.Default, name.GenderCode);

            var nationlityCodeParam = new SqlParameter("@psNationalityCode", SqlDbType.NVarChar, 3)
            {
                Direction = ParameterDirection.Output
            };
            var initialsParam = new SqlParameter("@psInitials", SqlDbType.NVarChar, 10)
            {
                Direction = ParameterDirection.Output
            };
            var searchKey1Param = new SqlParameter("@psSearchKey1", SqlDbType.NVarChar, 20)
            {
                Direction = ParameterDirection.Output
            };
            var searchKey2Param = new SqlParameter("@psSearchKey2", SqlDbType.NVarChar, 20)
            {
                Direction = ParameterDirection.Output
            };
            var nameStyleParam = new SqlParameter("@pnNameStyle", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            };
            var formalSalutationParam = new SqlParameter("@psFormalSalutation", SqlDbType.NVarChar, 50)
            {
                Direction = ParameterDirection.Output
            };
            var informalSalutationParam = new SqlParameter("@psInformalSalutation", SqlDbType.NVarChar, 50)
            {
                Direction = ParameterDirection.Output
            };

            sqlCommand.Parameters.AddRange(
                                           new[]
                                           {
                                               titleParam,
                                               countryParam,
                                               nationlityCodeParam,
                                               genderCodeParam,
                                               nameStyleParam,
                                               searchKey1Param,
                                               searchKey2Param,
                                               initialsParam,
                                               formalSalutationParam,
                                               informalSalutationParam,
                                               new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                               new SqlParameter("@psCulture", null), 
                                               new SqlParameter("@pbIsIndividual", name.Individual),
                                               new SqlParameter("@pbIsStaff", name.Staff),
                                               new SqlParameter("@psName", name.Name),
                                               new SqlParameter("@psFirstName", name.FirstName),
                                               new SqlParameter("@pbIsClient", name.Client),
                                               new SqlParameter("@pbIsSupplier", name.Supplier),
                                               new SqlParameter("@pbCalledFromCentura", false)
                                           });

            sqlCommand.ExecuteNonQuery();

            name.Title = titleParam.Value != DBNull.Value ? (string)titleParam.Value : null;
            name.HomeCountryCode = countryParam.Value != DBNull.Value ? (string) countryParam.Value : null;
            name.NationalityCode = nationlityCodeParam.Value != DBNull.Value ? (string)nationlityCodeParam.Value : null;
            name.Initials = initialsParam.Value != DBNull.Value ? (string)initialsParam.Value : null;
            name.GenderCode = genderCodeParam.Value != DBNull.Value ? (string)genderCodeParam.Value : null;
            name.SearchKey1 = searchKey1Param.Value != DBNull.Value ? (string)searchKey1Param.Value : null;
            name.SearchKey2 = searchKey2Param.Value != DBNull.Value ? (string)searchKey2Param.Value : null;
            name.NameStyleKey = nameStyleParam.Value != DBNull.Value ? (int?)nameStyleParam.Value : null;
            name.FormalSalutation = formalSalutationParam.Value != DBNull.Value ? (string) formalSalutationParam.Value : null;
            name.InformalSalutation = informalSalutationParam.Value != DBNull.Value ? (string)informalSalutationParam.Value : null;

            return name;
        }

        public string GenerateNameCode()
        {
            var sqlCommand = _dbContext.CreateStoredProcedureCommand("na_GenerateNameCode");

            var nameCodeParam = new SqlParameter("@psNameCode", SqlDbType.NVarChar, 10)
            {
                Direction = ParameterDirection.Output
            };

            sqlCommand.Parameters.AddRange(
                                           new[]
                                           {
                                               nameCodeParam,
                                               new SqlParameter("@pnUserIdentityId", _securityContext.User.Id)
                                           });

            sqlCommand.ExecuteNonQuery();
            return nameCodeParam.Value != DBNull.Value ? (string)nameCodeParam.Value : null;
        }
    }
}
