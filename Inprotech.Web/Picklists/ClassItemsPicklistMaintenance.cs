using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    public interface IClassItemsPicklistMaintenance
    {
        ClassItemSaveDetails Get(int classItemId);
        dynamic Save(ClassItemSaveDetails classItemSaveDetails, Operation operation);
        dynamic Delete(int classItemId, bool confirm);
    }

    public class ClassItemsPicklistMaintenance : IClassItemsPicklistMaintenance
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        public ClassItemsPicklistMaintenance(IDbContext dbContext, ILastInternalCodeGenerator lastInternalCodeGenerator)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _lastInternalCodeGenerator = lastInternalCodeGenerator ?? throw new ArgumentNullException(nameof(lastInternalCodeGenerator));
        }

        public ClassItemSaveDetails Get(int classItemId)
        {
            var classItem = _dbContext.Set<InprotechKaizen.Model.Configuration.ClassItem>()
                                      .SingleOrDefault(_ => _.Id.Equals(classItemId));

            if (classItem == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            return new ClassItemSaveDetails
            {
                Class = classItem.Class.Class,
                TmClassId = classItem.ClassId,
                SubClass = classItem.Class.SubClass,
                Country = classItem.Class.CountryCode,
                PropertyType = classItem.Class.PropertyType,
                ItemDescription = classItem.ItemDescription,
                ItemNo = classItem.ItemNo,
                Language = classItem.Language != null
                    ? new TableCodePicklistController.TableCodePicklistItem
                    {
                        Key = classItem.Language.Id,
                        Code = classItem.Language.UserCode,
                        Value = classItem.Language.Name
                    }
                    : null,
                IsDefaultItem = classItem.Language == null,
                Id = classItem.Id
            };
        }

        public dynamic Save(ClassItemSaveDetails classItemSaveDetails, Operation operation)
        {
            if (classItemSaveDetails == null) throw new ArgumentNullException(nameof(classItemSaveDetails));

            var validationErrors = Validate(classItemSaveDetails, operation).ToArray();
            if (!validationErrors.Any())
            {
                var itemNo = ItemNumber(classItemSaveDetails);
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var tmClass = classItemSaveDetails.TmClass(_dbContext).Id;
                    var model = operation == Operation.Update
                        ? _dbContext.Set<InprotechKaizen.Model.Configuration.ClassItem>()
                                    .Single(_ => _.Id == classItemSaveDetails.Id)
                        : _dbContext.Set<InprotechKaizen.Model.Configuration.ClassItem>()
                                    .Add(new InprotechKaizen.Model.Configuration.ClassItem(tmClass));

                    if (operation == Operation.Update)
                    {
                        var associatedItems = model.AssociatedItems(_dbContext);
                        var items = associatedItems as InprotechKaizen.Model.Configuration.ClassItem[] ?? associatedItems.ToArray();

                        if (items.Any())
                        {
                            foreach (var associatedItem in items)
                            {
                                associatedItem.ItemNo = itemNo;
                                associatedItem.ClassId = tmClass;
                            }
                        }

                        model.ClassId = tmClass;
                    }

                    model.ItemNo = itemNo;
                    model.LanguageCode = classItemSaveDetails.Language?.Key;
                    model.ItemDescription = classItemSaveDetails.ItemDescription;

                    _dbContext.SaveChanges();
                    tcs.Complete();

                    return new
                    {
                        Result = "success",
                        Key = model.Id,
                        RerunSearch = true
                    };
                }
            }

            return validationErrors.AsErrorResponse();
        }

        string ItemNumber(ClassItemSaveDetails classItemSaveDetails)
        {
            if (string.IsNullOrEmpty(classItemSaveDetails.ItemNo)
                && string.IsNullOrEmpty(classItemSaveDetails.SubClass)
                && classItemSaveDetails.Language == null)
            {
                classItemSaveDetails.ItemNo = Convert.ToString(_lastInternalCodeGenerator.GenerateNegativeLastInternalCode("CLASSITEM"));
            }
            return classItemSaveDetails.ItemNo;
        }

        public dynamic Delete(int classItemId, bool confirm)
        {
            try
            {
                if (_dbContext.Set<CaseClassItem>().Any(cci => cci.ClassItemId.Equals(classItemId)))
                    return KnownSqlErrors.CannotDelete.AsHandled();

                if (!confirm)
                {
                    var defaultItem = _dbContext.Set<InprotechKaizen.Model.Configuration.ClassItem>()
                                                .SingleOrDefault(ci => ci.Id.Equals(classItemId) && ci.Language == null);

                    if (defaultItem != null && defaultItem.AssociatedItems(_dbContext).Any())
                    {
                        return new
                        {
                            Result = "confirmation",
                            Message = ConfigurationResources.ClassItemDeleteValidation
                        };
                    }
                }

                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = _dbContext
                        .Set<InprotechKaizen.Model.Configuration.ClassItem>()
                        .Single(_ => _.Id.Equals(classItemId));

                    if (model.Language == null)
                    {
                        var associatedItems = model.AssociatedItems(_dbContext).ToArray();
                        if (associatedItems.Any())
                        {
                            _dbContext.RemoveRange(associatedItems);
                        }
                    }

                    _dbContext.Set<InprotechKaizen.Model.Configuration.ClassItem>().Remove(model);

                    _dbContext.SaveChanges();
                    tcs.Complete();
                }

                return new
                {
                    Result = "success",
                    RerunSearch = confirm
                };
            }
            catch (Exception ex)
            {
                if (!ex.IsForeignKeyConstraintViolation())
                    throw;

                return KnownSqlErrors.CannotDelete.AsHandled();
            }
        }

        IEnumerable<ValidationError> Validate(ClassItemSaveDetails classItemSaveDetails, Operation operation)
        {
            var all = _dbContext.Set<InprotechKaizen.Model.Configuration.ClassItem>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != classItemSaveDetails.Id))
            {
                throw new ArgumentException(ConfigurationResources.RecordNotFoundForUpdate);
            }

            foreach (var validationError in CommonValidations.Validate(classItemSaveDetails))
                yield return validationError;

            var others = operation == Operation.Update ? all.Where(_ => _.Id != classItemSaveDetails.Id).ToArray() : all;

            if ((!string.IsNullOrEmpty(classItemSaveDetails.SubClass) && string.IsNullOrEmpty(classItemSaveDetails.ItemNo))
                || (string.IsNullOrEmpty(classItemSaveDetails.SubClass)
                                                && string.IsNullOrEmpty(classItemSaveDetails.ItemNo)
                                                && classItemSaveDetails.Language != null))
            {
                yield return ValidationErrors.Required("itemNo");
                yield break;
            }
            if (operation == Operation.Add && classItemSaveDetails.Language != null
                          && !DefaultItemExists(others, classItemSaveDetails))
            {
                yield return ValidationErrors.SetCustomError(string.Empty, "field.errors.defaultItemRequired", string.Empty, true);
                yield break;
            }
            if (ItemDescriptionExists(others, classItemSaveDetails))
            {
                yield return ValidationErrors.NotUnique("itemDescription");
                yield break;
            }
            if (!string.IsNullOrEmpty(classItemSaveDetails.ItemNo) && ValidateUnique(others, classItemSaveDetails))
            {
                yield return ValidationErrors.SetCustomError(string.Empty, "field.errors.uniqueItemCombination", string.Empty, true);
            }
        }

        bool ItemDescriptionExists(InprotechKaizen.Model.Configuration.ClassItem[] others, ClassItemSaveDetails classItemSaveDetails)
        {
            var relevant = others.Where(_ => _.Class.CountryCode.Equals(classItemSaveDetails.Country)
                                             && _.Class.PropertyType.Equals(classItemSaveDetails.PropertyType)
                                             && _.Class.Class.Equals(classItemSaveDetails.Class));

            return relevant.Any(_ => _.ItemDescription.IgnoreCaseEquals(classItemSaveDetails.ItemDescription));
        }

        bool DefaultItemExists(InprotechKaizen.Model.Configuration.ClassItem[] others, ClassItemSaveDetails classItemSaveDetails)
        {
            var relevant = others.SingleOrDefault(ci => ci.ItemNo.Equals(classItemSaveDetails.ItemNo)
                                              && ci.Class.CountryCode.Equals(classItemSaveDetails.Country)
                                              && ci.Class.PropertyType.Equals(classItemSaveDetails.PropertyType)
                                              && ci.Class.Class.Equals(classItemSaveDetails.Class)
                                              && ci.Class.SubClass == classItemSaveDetails.SubClass
                                              && !ci.LanguageCode.HasValue);

            return relevant != null;
        }

        bool ValidateUnique(InprotechKaizen.Model.Configuration.ClassItem[] others, ClassItemSaveDetails classItemSaveDetails)
        {
            var languageCode = classItemSaveDetails.Language?.Key;
            var exists = others.Any(ci => ci.ItemNo.Equals(classItemSaveDetails.ItemNo)
                                                && ci.Class.CountryCode.Equals(classItemSaveDetails.Country)
                                                && ci.Class.PropertyType.Equals(classItemSaveDetails.PropertyType)
                                                && ci.Class.Class.Equals(classItemSaveDetails.Class)
                                                && ci.Class.SubClass == classItemSaveDetails.SubClass
                                                && ci.LanguageCode == languageCode);
            return exists;
        }
    }

    public static class ClassItemExtensions
    {
        public static InprotechKaizen.Model.Configuration.ClassItem DefaultParentItem(this ClassItemSaveDetails classItemSaveDetails, IDbContext dbContext)
        {
            var defaultItem = dbContext.Set<InprotechKaizen.Model.Configuration.ClassItem>()
                                       .Single(_ => _.Class.Class.Equals(classItemSaveDetails.Class)
                                                    && _.Class.SubClass == classItemSaveDetails.SubClass
                                                    && _.Class.CountryCode.Equals(classItemSaveDetails.Country)
                                                    && _.Class.PropertyType.Equals(classItemSaveDetails.PropertyType)
                                                    && !_.LanguageCode.HasValue);
            return defaultItem;
        }

        public static IEnumerable<InprotechKaizen.Model.Configuration.ClassItem> AssociatedItems(this InprotechKaizen.Model.Configuration.ClassItem classItem, IDbContext dbContext)
        {
            var associatedItems = dbContext.Set<InprotechKaizen.Model.Configuration.ClassItem>()
                                           .Where(_ => _.ItemNo.Equals(classItem.ItemNo)
                                                       && _.Class.CountryCode.Equals(classItem.Class.CountryCode)
                                                       && _.Class.PropertyType.Equals(classItem.Class.PropertyType)
                                                       && _.Class.Class.Equals(classItem.Class.Class)
                                                       && _.Class.SubClass == classItem.Class.SubClass
                                                       && _.LanguageCode != classItem.LanguageCode);
            return associatedItems;
        }

        public static TmClass TmClass(this ClassItemSaveDetails classItemSaveDetails, IDbContext dbContext)
        {
            var tmClass = dbContext.Set<TmClass>().Single(_ => _.CountryCode.Equals(classItemSaveDetails.Country)
                                                               && _.PropertyType.Equals(classItemSaveDetails.PropertyType)
                                                               && _.Class.Equals(classItemSaveDetails.Class)
                                                               && _.SubClass == classItemSaveDetails.SubClass);

            return tmClass;
        }
    }
}

