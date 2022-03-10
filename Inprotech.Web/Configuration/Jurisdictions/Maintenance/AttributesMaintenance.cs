using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Jurisdictions.Maintenance
{
    public interface IAttributesMaintenance
    {
        void Save(Delta<AttributesMaintenanceModel> attributesDelta);

        IEnumerable<ValidationError> Validate(Delta<AttributesMaintenanceModel> delta, IList<AttributesMaintenanceModel> attributes);
    }

    public class AttributesMaintenance : IAttributesMaintenance
    {
        readonly IDbContext _dbContext;

        public AttributesMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public void Save(Delta<AttributesMaintenanceModel> attributesDelta)
        {
            AddAttributes(attributesDelta.Added);
            UpdateAttributes(attributesDelta.Updated);
            DeleteAttributes(attributesDelta.Deleted);
        }

        void AddAttributes(ICollection<AttributesMaintenanceModel> added)
        {
            if (!added.Any()) return;

            var all = _dbContext.Set<TableAttributes>();

            foreach (var item in added)
            {
                if (item.ValueId == null) continue;
                var saveModel = new TableAttributes(KnownTableAttributes.Country, item.CountryCode)
                {
                    SourceTableId = item.TypeId,
                    TableCodeId = item.ValueId.Value
                };

                all.Add(saveModel);
            }
        }

        void UpdateAttributes(ICollection<AttributesMaintenanceModel> updated)
        {
            if(!updated.Any()) return;

            foreach (var attr in updated)
            {
                var data = _dbContext.Set<TableAttributes>().SingleOrDefault(_ => _.Id == attr.Id);
                if (data == null) continue;
                data.SourceTableId = attr.TypeId;
                if (attr.ValueId != null) data.TableCodeId = attr.ValueId.Value;
            }
        }

        void DeleteAttributes(ICollection<AttributesMaintenanceModel> deleted)
        {
            if (!deleted.Any()) return;

            var attributesToDelete = deleted.Select(item => _dbContext.Set<TableAttributes>().SingleOrDefault(_ => _.Id == item.Id)).Where(item => item != null);
            _dbContext.RemoveRange(attributesToDelete);
        }

        public IEnumerable<ValidationError> Validate(Delta<AttributesMaintenanceModel> delta, IList<AttributesMaintenanceModel> attributes)
        {
            if (delta == null) throw new ArgumentNullException(nameof(delta));

            var errorsList = new List<ValidationError>();

            var combinedDelta = delta.Added.Union(delta.Updated).ToList();

            if(combinedDelta.Any(_ => _.TypeId == null || _.ValueId == null))
            {
                errorsList.Add(ValidationErrors.TopicError("attributes", "Mandatory field was empty."));
            }
            if (combinedDelta.Any(IsDuplicate))
            {
                errorsList.Add(ValidationErrors.TopicError("attributes", ConfigurationResources.DuplicateJurisdictionAttribute));
            }

            var selectionTypes = _dbContext.Set<SelectionTypes>().Where(sel => sel.ParentTable == KnownTableAttributes.Country).ToArray();
            var attributesToBeValidated = attributes.Except(delta.Deleted, new AttributeEqualityComparer()).ToList();
            var attributesGroupedByType = attributesToBeValidated.GroupBy(_ => _.TypeId).ToArray();
            foreach (var selType in selectionTypes)
            {
                var attributesByType = attributesGroupedByType.FirstOrDefault(_ => _.Key == selType.TableTypeId);
                if (attributesByType != null && attributesByType.Count() > selType?.MaximumAllowed)
                {
                    errorsList.Add(ValidationErrors.TopicError("attributes", string.Format(ConfigurationResources.MaxAttributesError, selType.TableType.Name)));
                }
                if ((selType?.MinimumAllowed > 0 && attributesByType == null) || (attributesByType != null && attributesByType.Count() < selType?.MinimumAllowed))
                {
                    errorsList.Add(ValidationErrors.TopicError("attributes", string.Format(ConfigurationResources.MinAttributesError, selType.TableType.Name, selType.MinimumAllowed)));
                }
            }
            return errorsList;
        }

        bool IsDuplicate(AttributesMaintenanceModel model)
        {
            return _dbContext.Set<TableAttributes>().Any(_ => _.ParentTable == KnownTableAttributes.Country && _.GenericKey == model.CountryCode && _.SourceTableId == model.TypeId && _.TableCodeId == model.ValueId && _.Id != model.Id);
        }
    }

    public class AttributesMaintenanceModel
    {
        public int? Id { get; set; }

        public string CountryCode { get; set; }

        public short? TypeId { get; set; }

        public int? ValueId { get; set; }    
    }

    public class AttributeEqualityComparer : IEqualityComparer<AttributesMaintenanceModel>
    {
        [SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "1")]
        public bool Equals(AttributesMaintenanceModel x, AttributesMaintenanceModel y)
        {
            if (ReferenceEquals(x, null)) return false;

            if (ReferenceEquals(x, y)) return true;

            return y != null && (x.Id == y.Id &&
                                 x.CountryCode == y.CountryCode &&
                                 x.TypeId == y.TypeId &&
                                 x.ValueId == y.ValueId);
        }

        [SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public int GetHashCode(AttributesMaintenanceModel obj)
        {
            return new
            {
                obj.Id,
                obj.CountryCode,
                obj.TypeId,
                obj.ValueId
            }.GetHashCode();
        }
    }
}
