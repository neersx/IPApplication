using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.ValidCombinations;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using State = InprotechKaizen.Model.Names.State;

namespace Inprotech.Web.Configuration.Jurisdictions
{
    public interface IJurisdictionDetails
    {
        dynamic GetOverview(string id);
        dynamic GetGroups(string id, CommonQueryParameters queryParameters);
        dynamic GetMembers(string id, CommonQueryParameters queryParameters);
        dynamic GetAttributes(string id, CommonQueryParameters queryParameters);
        dynamic GetTexts(string id, CommonQueryParameters queryParameters);
        dynamic GetStatusFlags(string id, CommonQueryParameters queryParameters);

        IEnumerable<CountryHoliday> GetHolidays(string id);

        dynamic GetHolidayById(string id, int holidayId);
        dynamic GetStates(string id, CommonQueryParameters queryParameters);
        dynamic GetValidNumbers(string id, CommonQueryParameters queryParameters);
        dynamic GetValidCombinations(string id);
        dynamic GetClasses(string id, CommonQueryParameters queryParameters);
        dynamic TaxExemptOptions();
        string DayOfWeek(DateTime date);
    }

    public class JurisdictionDetails : IJurisdictionDetails
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IValidJurisdictionsDetails _validJurisdictionsDetails;
        
        public JurisdictionDetails(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, IValidJurisdictionsDetails validJurisdictionsDetails, ITaskSecurityProvider taskSecurityProvider)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _validJurisdictionsDetails = validJurisdictionsDetails;
            _taskSecurityProvider = taskSecurityProvider;
        }

        public dynamic TaxExemptOptions()
        {
            var culture = _preferredCultureResolver.Resolve();

            var taxExemptOptions = _dbContext.Set<InprotechKaizen.Model.Accounting.Tax.TaxRate>().Select(_ => new
            {
                Id = _.Code,
                Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
            }).ToArray();

            return taxExemptOptions;
        }

        public string DayOfWeek(DateTime date)
        {
            var cultureInfo = new System.Globalization.CultureInfo(_preferredCultureResolver.Resolve());

            return cultureInfo.DateTimeFormat.GetDayName(date.DayOfWeek);
        }

        public dynamic GetOverview(string id)
        {
            if (id == null) throw new ArgumentNullException(nameof(id));

            var culture = _preferredCultureResolver.Resolve();
            var canEdit = CanEdit();

            var j = from _ in _dbContext.Set<Country>()
                    where _.Id == id
                    select new JurisdictionModel
                    {
                        Id = _.Id,
                        Type = _.Type,
                        AlternateCode = _.AlternateCode,
                        Name = _.Name,
                        Abbreviation = _.Abbreviation,
                        PostalName = _.PostalName,
                        InformalName = _.InformalName,
                        CountryAdjective = _.CountryAdjective,
                        IsdCode = _.IsdCode,
                        ReportPriorArt = _.ReportPriorArt,
                        Notes = _.Notes,
                        DateCommenced = _.DateCommenced,
                        DateCeased = _.DateCeased,
                        WorkDayFlag = _.WorkDayFlag,
                        StateLabel = canEdit ? _.StateLabel : DbFuncs.GetTranslation(_.StateLabel, null, _.StateLabelTId, culture),
                        StateAbbreviated = _.StateAbbreviated == 1,
                        PostCodeLiteral = canEdit ? _.PostCodeLiteral : DbFuncs.GetTranslation(_.PostCodeLiteral, null, _.PostCodeLiteralTId, culture),
                        PostCodeFirst = _.PostCodeFirst == 1,
                        NameStyle = _.NameStyle != null ? new TableCodePicklistController.TableCodePicklistItem
                        {
                            Key = _.NameStyle.Id,
                            Code = _.NameStyle.UserCode,
                            Value = DbFuncs.GetTranslation(_.NameStyle.Name, null, _.NameStyle.NameTId, culture)
                        }
                        : null,
                        AddressStyle = _.AddressStyle != null ? new TableCodePicklistController.TableCodePicklistItem
                        {
                            Key = _.AddressStyle.Id,
                            Code = _.AddressStyle.UserCode,
                            Value = DbFuncs.GetTranslation(_.AddressStyle.Name, null, _.AddressStyle.NameTId, culture)
                        }
                        : null,
                        PopulateCityFromPostCode = _.PostCodeSearchCode != null ? new TableCodePicklistController.TableCodePicklistItem
                        {
                            Key = _.PostCodeSearchCode.Id,
                            Code = _.PostCodeSearchCode.UserCode,
                            Value = DbFuncs.GetTranslation(_.PostCodeSearchCode.Name, null, _.PostCodeSearchCode.NameTId, culture)
                        }
                        : null,
                        PostCodeAutoFlag = _.PostCodeAutoFlag == 1,
                        DefaultTaxRate = _.DefaultTaxRate != null ? new TaxRate
                        {
                            Id = _.DefaultTaxRate.Code,
                            Description = DbFuncs.GetTranslation(_.DefaultTaxRate.Description, null, _.DefaultTaxRate.DescriptionTId, culture)
                        }
                        : null,
                        DefaultCurrency = _.DefaultCurrency != null ? new Picklists.Currency
                        {
                            Id = _.DefaultCurrency.Id,
                            Code = _.DefaultCurrency.Id,
                            Description = DbFuncs.GetTranslation(_.DefaultCurrency.Description, null, _.DefaultCurrency.DescriptionTId, culture)
                        }
                        : null,
                        IsTaxNumberMandatory = _.TaxNoMandatory == 1m,
                        CanEdit = canEdit,
                        AllMembersFlag = _.AllMembersFlag == 1
                    };

            if (!j.Any()) throw Exceptions.NotFound("Jurisdiction not found");

            return CountryExtensions.WithType(j.FirstOrDefault());
        }

        public dynamic GetGroups(string id, CommonQueryParameters queryParameters)
        {
            if (id == null) throw new ArgumentNullException(nameof(id));
            if (queryParameters == null) throw new ArgumentNullException(nameof(queryParameters));
            var culture = _preferredCultureResolver.Resolve();

            var groups = _dbContext.Set<CountryGroup>()
                             .Where(_ => _.MemberCountry == id)
                             .Include(g => g.GroupCountry)
                             .Select(g => new
                             {
                                 g.Id,
                                 Name = DbFuncs.GetTranslation(g.GroupCountry.Name, null, g.GroupCountry.NameTId, culture),
                                 IsAssociateMember = g.AssociateMember == 1,
                                 g.DateCommenced,
                                 g.DateCeased,
                                 g.FullMembershipDate,
                                 g.AssociateMemberDate,
                                 IsGroupDefault = g.DefaultFlag == 1,
                                 g.PreventNationalPhase,
                                 g.PropertyTypes
                             })
                             .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir).ToArray();

            return groups.Select(_ => new
            {
                _.Id,
                _.Name,
                _.IsAssociateMember,
                _.DateCommenced,
                _.DateCeased,
                _.FullMembershipDate,
                _.AssociateMemberDate,
                _.IsGroupDefault,
                _.PreventNationalPhase,
                _.PropertyTypes,
                PropertyTypesName = string.IsNullOrEmpty(_.PropertyTypes) ? null : string.Join(", ", PropertyTypes(_, ValidProperties(_.Id)).OrderBy(a => a.Value).Select(ic => ic.Value)),
                PropertyTypeCollection = string.IsNullOrEmpty(_.PropertyTypes) ? null : PropertyTypes(_, ValidProperties(_.Id)).OrderBy(a => a.Code)
            });
        }

        public dynamic GetMembers(string id, CommonQueryParameters queryParameters)
        {
            if (id == null) throw new ArgumentNullException(nameof(id));
            if (queryParameters == null) throw new ArgumentNullException(nameof(queryParameters));
            var culture = _preferredCultureResolver.Resolve();
            var validProperties = ValidProperties(id);

            var members = _dbContext.Set<CountryGroup>()
                             .Where(_ => _.Id == id)
                             .Include(c => c.GroupMember)
                             .Select(g => new
                             {
                                 Id = g.MemberCountry,
                                 Name = DbFuncs.GetTranslation(g.GroupMember.Name, null, g.GroupMember.NameTId, culture),
                                 IsAssociateMember = g.AssociateMember == 1,
                                 g.DateCommenced,
                                 g.DateCeased,
                                 g.FullMembershipDate,
                                 g.AssociateMemberDate,
                                 IsGroupDefault = g.DefaultFlag == 1,
                                 g.PreventNationalPhase,
                                 g.PropertyTypes
                             })
                             .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir).ToArray();

            return members.Select(_ => new
            {
                _.Id,
                _.Name,
                _.IsAssociateMember,
                _.DateCommenced,
                _.DateCeased,
                _.FullMembershipDate,
                _.AssociateMemberDate,
                _.IsGroupDefault,
                _.PreventNationalPhase,
                _.PropertyTypes,
                PropertyTypesName = string.IsNullOrEmpty(_.PropertyTypes) ? null : string.Join(", ", PropertyTypes(_, validProperties).OrderBy(a => a.Value).Select(ic => ic.Value)),
                PropertyTypeCollection = string.IsNullOrEmpty(_.PropertyTypes) ? null : PropertyTypes(_, validProperties).OrderBy(a => a.Code)
            });
        }

        ValidProperty[] ValidProperties(string id)
        {
            var validProperties = _dbContext.Set<ValidProperty>().Where(_ => _.CountryId == id).ToArray();
            if (!validProperties.Any())
            {
                validProperties = _dbContext.Set<ValidProperty>().Where(_ => _.CountryId == KnownValues.DefaultCountryCode).ToArray();
            }
            return validProperties;
        }

        IEnumerable<ValidPropertyPickList> PropertyTypes(dynamic _, IEnumerable<ValidProperty> validProperties)
        {
            return validProperties.Where(i => Enumerable.Contains(_.PropertyTypes.Split(','), i.PropertyTypeId))
                                                                                 .Select(ic => new ValidPropertyPickList
                                                                                 {
                                                                                     Key = ic.PropertyType.Id,
                                                                                     Code = ic.PropertyTypeId,
                                                                                     Value = ic.PropertyName
                                                                                 });
        }

        public dynamic GetAttributes(string id, CommonQueryParameters queryParameters)
        {
            if (id == null) throw new ArgumentNullException(nameof(id));
            var culture = _preferredCultureResolver.Resolve();

            var attributes = (from ta in _dbContext.Set<TableAttributes>().Where(e => e.GenericKey == id)
                    join tt in _dbContext.Set<TableType>() on ta.SourceTableId equals tt.Id
                    join tc in _dbContext.Set<TableCode>() on ta.TableCodeId equals tc.Id into t1
                    from tcr in t1.DefaultIfEmpty()
                    select new
                    {
                        ta.Id,
                        CountryCode = ta.GenericKey,
                        TypeId = tt.Id,
                        TypeName = DbFuncs.GetTranslation(tt.Name, null, tt.NameTId, culture),
                        ValueId = tcr.Id,
                        Value = DbFuncs.GetTranslation(tcr.Name, null, tcr.NameTId, culture),
                        Attributes = tt.TableCodes.OrderBy(_ => _.Name).Select(_ => new { Key = _.Id, Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture) })
                    })
                .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir).OrderBy(_ => _.TypeName).ThenBy(_ => _.Value);

            return attributes;
        }

        public dynamic GetTexts(string id, CommonQueryParameters queryParameters)
        {
            var countryTexts =
                _dbContext.Set<CountryText>()
                          .Where(_ => _.CountryId == id)
                          .Include(c => c.TextType)
                          .Include(t => t.Property);
            _preferredCultureResolver.Resolve();

            return countryTexts
                .Select(v => new
                {
                    TextType = new TableCodePicklistController.TableCodePicklistItem
                    {
                        Key = v.TextType.Id,
                        Code = v.TextType.UserCode,
                        Value = v.TextType.Name
                    },
                    PropertyType = v.PropertyType != null
                        ? new Picklists.PropertyType
                        {
                            Key = v.Property.Id,
                            Code = v.Property.Code,
                            Value = v.Property.Name

                        }
                        : null,
                    v.Text,
                    v.CountryId,
                    v.SequenceId
                })
                .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir).OrderBy(_ => _.TextType.Value).ThenBy(_ => _.PropertyType.Value);
        }

        public dynamic GetStatusFlags(string id, CommonQueryParameters queryParameters)
        {
            var country = _dbContext.Set<Country>().SingleOrDefault(_ => _.Id == id);
            if (country == null) throw Exceptions.NotFound("Jurisdiction not found");
            var culture = _preferredCultureResolver.Resolve();

            if (string.IsNullOrWhiteSpace(queryParameters.SortBy))
            {
                queryParameters.SortBy = "Id";
            }

            var statusFlagsAll =
                _dbContext.Set<CountryFlag>().Where(_ => _.CountryId == id).Select(_ => new
                {
                    Id = _.FlagNumber,
                    _.CountryId,
                    _.Name,
                    NameTranslated = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                    AllowNationalPhase = _.AllowNationalPhase == 1,
                    RestrictRemoval = _.RestrictRemoval == 1,
                    _.Status,
                    _.ProfileName
                }).ToArray();

            var statusFlags = statusFlagsAll.Select(_ => new
            {
                _.Id,
                _.CountryId,
                _.Name,
                _.NameTranslated,
                _.AllowNationalPhase,
                _.RestrictRemoval,
                _.Status,
                RegistrationStatus = ((KnownRegistrationStatus)_.Status).ToString(),
                _.ProfileName
            });

            return statusFlags.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir);
        }

        public dynamic GetHolidays(string id, CommonQueryParameters queryParameters)
        {
            if (string.IsNullOrWhiteSpace(queryParameters.SortBy))
            {
                queryParameters.SortBy = "HolidayDate";
            }

            var holidays =GetHolidays(id);

            var cultureInfo = new System.Globalization.CultureInfo(_preferredCultureResolver.Resolve());

            return holidays
                .Select(v => new
                {
                    v.Id,
                    Holiday = v.HolidayName,
                    DayOfWeek = cultureInfo.DateTimeFormat.GetDayName(v.HolidayDate.DayOfWeek),
                    v.HolidayDate,
                    v.CountryId
                })
                .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir);
        }

        public IEnumerable<CountryHoliday> GetHolidays(string id)
        {
            return _dbContext.Set<CountryHoliday>()
                             .Where(_ => _.CountryId == id);
        }

        public dynamic GetHolidayById(string id, int holidayId)
        {
            var holiday = _dbContext.Set<CountryHoliday>()
                                 .SingleOrDefault(_ => _.CountryId == id && _.Id == holidayId);

            if (holiday == null) return null;
            var cultureInfo = new System.Globalization.CultureInfo(_preferredCultureResolver.Resolve());

            return new
            {
                holiday.Id,
                Holiday = holiday.HolidayName,
                DayOfWeek = cultureInfo.DateTimeFormat.GetDayName(holiday.HolidayDate.DayOfWeek),
                holiday.HolidayDate,
                holiday.CountryId
            };
        }

        public dynamic GetStates(string id, CommonQueryParameters queryParameters)
        {
            var culture = _preferredCultureResolver.Resolve();
            var states = _dbContext.Set<State>().Where(_ => _.CountryCode == id)
                                   .Select(_ => new { _.Id, _.CountryCode, _.Code, _.Name, TranslatedName = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture) });
            return states
                .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir);
        }

        public dynamic GetValidNumbers(string id, CommonQueryParameters queryParameters)
        {
            var culture = _preferredCultureResolver.Resolve();
            if (string.IsNullOrWhiteSpace(queryParameters.SortBy))
            {
                queryParameters.SortBy = "PropertyTypeName";
            }

            var validNumbers = _dbContext.Set<CountryValidNumber>().Where(_ => _.CountryId == id)
                                         .Select(_ => new
                                         {
                                             _.Id,
                                             ValidPropertyName = _.ValidProperty != null ? DbFuncs.GetTranslation(_.ValidProperty.PropertyName, null, _.ValidProperty.PropertyNameTId, culture) : null,
                                             PropertyTypeName = DbFuncs.GetTranslation(_.Property.Name, null, _.Property.NameTId, culture),
                                             PropertyTypeCode = _.PropertyId,
                                             CaseTypeName = _.CaseType != null ? DbFuncs.GetTranslation(_.CaseType.Name, null, _.CaseType.NameTId, culture) : null,
                                             CaseTypeCode = _.CaseTypeId,
                                             ValidCaseCategoryName = _.ValidCaseCategory != null ? DbFuncs.GetTranslation(_.ValidCaseCategory.CaseCategoryDesc, null, _.ValidCaseCategory.CaseCategoryDescTid, culture) : null,
                                             CaseCategoryName = _.CaseCategory != null ? DbFuncs.GetTranslation(_.CaseCategory.Name, null, _.CaseCategory.NameTId, culture) : null,
                                             CaseCategoryCode = _.CaseCategoryId,
                                             ValidSubTypeName = _.ValidSubType != null ? DbFuncs.GetTranslation(_.ValidSubType.SubTypeDescription, null, _.ValidSubType.SubTypeDescriptionTid, culture) : null,
                                             SubTypeName = _.SubType != null ? DbFuncs.GetTranslation(_.SubType.Name, null, _.SubType.NameTId, culture) : null,
                                             SubTypeCode = _.SubTypeId,
                                             NumberTypeName = DbFuncs.GetTranslation(_.NumberType.Name, null, _.NumberType.NameTId, culture),
                                             NumberTypeCode = _.NumberTypeId,
                                             _.Pattern,
                                             _.ValidFrom,
                                             WarningFlag = _.WarningFlag == 1,
                                             AdditionalValidationId = _.AdditionalValidation != null ? _.AdditionalValidation.Id : (int?)null,
                                             AdditionalValidationName = _.AdditionalValidation != null ? _.AdditionalValidation.Name : null,
                                             DisplayMessage = DbFuncs.GetTranslation(_.ErrorMessage, null, _.ErrorMessageTId, culture)
                                         }).ToArray();

            return validNumbers.Select(_ => new
            {
                _.Id,
                PropertyTypeName = string.IsNullOrEmpty(_.ValidPropertyName) ? _.PropertyTypeName : _.ValidPropertyName,
                _.PropertyTypeCode,
                _.NumberTypeName,
                _.NumberTypeCode,
                _.CaseTypeName,
                _.CaseTypeCode,
                SubTypeName = string.IsNullOrEmpty(_.ValidSubTypeName) && !string.IsNullOrEmpty(_.SubTypeCode) ? _.SubTypeName : _.ValidSubTypeName,
                _.SubTypeCode,
                CaseCategoryName = string.IsNullOrEmpty(_.ValidCaseCategoryName) && !string.IsNullOrEmpty(_.CaseCategoryCode) ? _.CaseCategoryName : _.ValidCaseCategoryName,
                _.CaseCategoryCode,
                _.Pattern,
                _.ValidFrom,
                _.WarningFlag,
                _.AdditionalValidationId,
                _.AdditionalValidationName,
                _.DisplayMessage
            }).OrderByProperty(queryParameters.SortBy, queryParameters.SortDir);
        }

        public dynamic GetValidCombinations(string id)
        {
            var search = new ValidCombinationSearchCriteria();
            search.Jurisdictions = search.Jurisdictions.Concat(new[] { id });
            var v = _validJurisdictionsDetails.SearchValidJurisdiction(search).Any();

            return new { HasCombinations = v, CanAccessValidCombinations = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainValidCombinations, ApplicationTaskAccessLevel.Execute) };
        }

        public dynamic GetClasses(string id, CommonQueryParameters queryParameters)
        {
            var culture = _preferredCultureResolver.Resolve();

            var validCombination = _dbContext.Set<ValidProperty>().Where(_ => _.CountryId == id)
                                             .Select(_ => new { _.PropertyTypeId, Name = DbFuncs.GetTranslation(_.PropertyName, null, _.PropertyNameTId, culture) }).ToDictionary(_ => _.PropertyTypeId, _ => _.Name);

            var defaultClasses = _dbContext.Set<TmClass>()
                                           .Where(_ => _.CountryCode == KnownValues.DefaultCountryCode)
                                           .ToArray()
                                           .Select(_ => new
                                           {
                                               _.Id,
                                               _.Class,
                                               Description = DbFuncs.GetTranslation(_.Heading, null, _.HeadingTId, culture),
                                               _.SubClass,
                                               PropertyType = DbFuncs.GetTranslation(_.Property.Name, null, _.Property.NameTId, culture),
                                               PropertyTypeCode = _.PropertyType,
                                               _.Property.AllowSubClass,
                                               _.EffectiveDate,
                                               _.Notes,
                                               ItemsCount = ItemsCount(_, id)
                                           });

            if (id == KnownValues.DefaultCountryCode)
            {
                return defaultClasses.SortClasses(queryParameters).ThenBy(_ => _.SubClass);
            }

            var localClasses = _dbContext.Set<TmClass>()
                                         .Where(_ => _.CountryCode == id)
                                         .ToArray()
                                         .Select(_ => new
                                         {
                                             _.Id,
                                             _.Class,
                                             Description = DbFuncs.GetTranslation(_.Heading, null, _.HeadingTId, culture),
                                             _.SubClass,
                                             PropertyType = DbFuncs.GetTranslation(_.Property.Name, null, _.Property.NameTId, culture),
                                             PropertyTypeCode = _.PropertyType,
                                             _.Property.AllowSubClass,
                                             IntClasses = _.IntClass ?? string.Empty,
                                             _.EffectiveDate,
                                             _.Notes,
                                             ItemsCount = ItemsCount(_, id)
                                         });

            var classesWithInternational = localClasses.Select(
                                                               _ => new
                                                               {
                                                                   _.Id,
                                                                   _.Class,
                                                                   _.Description,
                                                                   IntClasses = _.IntClasses.Sort(),
                                                                   _.SubClass,
                                                                   PropertyType = validCombination.ContainsKey(_.PropertyTypeCode) ? validCombination[_.PropertyTypeCode] : _.PropertyType,
                                                                   _.PropertyTypeCode,
                                                                   _.AllowSubClass,
                                                                   _.EffectiveDate,
                                                                   _.Notes,
                                                                   InternationalClasses = defaultClasses.Where(i => _.IntClasses.Split(',', ' ').Contains(i.Class) && i.PropertyTypeCode == _.PropertyTypeCode)
                                                                                                        .Select(ic => new
                                                                                                        {
                                                                                                            Key = ic.Id,
                                                                                                            Code = ic.Class,
                                                                                                            Value = ic.Description
                                                                                                        }).OrderByNumeric("Code", "asc"),
                                                                   _.ItemsCount
                                                               }
                                                              ).ToArray();
            
            return classesWithInternational.SortClasses(queryParameters).ThenBy(_ => _.SubClass);
        }

        int ItemsCount(TmClass _, string countryCode)
        {
            var classItems = _dbContext.Set<InprotechKaizen.Model.Configuration.ClassItem>().AsQueryable();

            return _.Property.AllowSubClass == 2
                ? string.IsNullOrEmpty(_.SubClass)
                    ? classItems.Count(ci => !ci.LanguageCode.HasValue && ci.Class.CountryCode.Equals(countryCode) && ci.Class.PropertyType.Equals(_.PropertyType) && ci.Class.Class.Equals(_.Class))
                    : classItems.Count(ci => !ci.LanguageCode.HasValue && ci.Class.CountryCode.Equals(countryCode) && ci.Class.PropertyType.Equals(_.PropertyType) && ci.Class.Class.Equals(_.Class) && ci.Class.SubClass.Equals(_.SubClass))
                : 0;
        }
        
        public bool CanEdit()
        {
            return _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainJurisdiction, ApplicationTaskAccessLevel.Execute);
        }

        public class ClassWithInternational
        {
            public string Id { get; set; }
            public string Description { get; set; }
            public string SubClass { get; set; }
            public string PropertyType { get; set; }
            public dynamic[] InternationalClasses { get; set; }
        }

        public class ValidPropertyPickList
        {
            public int Key { get; set; }
            public string Code { get; set; }
            public string Value { get; set; }
        }
    }

    public static class SortedInternationalClass
    {
        const string SortByClassField = "class";

        public static string Sort(this string intClasses)
        {
            return string.IsNullOrEmpty(intClasses) ? null : string.Join(", ", intClasses.Split(',')
                                                                    .OrderBy(o => o, new NumericComparer()).ToArray());
        }

        public static IOrderedEnumerable<TEntity> SortClasses<TEntity>(this IEnumerable<TEntity> source,
                                                                CommonQueryParameters queryParameters) where TEntity : class
        {
            if (string.IsNullOrEmpty(queryParameters.SortBy))
            {
                return source.OrderByProperty("PropertyType", "asc")
                             .ThenByNumeric(SortByClassField, queryParameters.SortDir);
            }

            if (!string.IsNullOrEmpty(queryParameters.SortBy) && queryParameters.SortBy == SortByClassField)
            {
                return source.OrderByNumeric(SortByClassField, queryParameters.SortDir);
            }

            return source.OrderByProperty(queryParameters.SortBy, queryParameters.SortDir);
        }
    }
}