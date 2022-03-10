using System;
using System.Collections.Generic;
using System.Linq;

namespace InprotechKaizen.Model.Components.Translations
{
    public interface ITranslation
    {
        string Translate(object entity, string propertyName);
    }

    class Translation : ITranslation
    {
        readonly IDictionary<string, IDictionary<string, string>> _idToTranslation;
        
        public Translation(IDictionary<object, IDictionary<string, string>> entityToTranslation)
        {
            if (entityToTranslation == null) throw new ArgumentNullException("entityToTranslation");

            _idToTranslation = entityToTranslation.ToDictionary(a => Utilities.GetUniqueId(a.Key), a => a.Value);
        }

        public string Translate(object entity, string propertyName)
        {
            if (entity == null) throw new ArgumentNullException("entity");
            if (propertyName == null) throw new ArgumentNullException("propertyName");

            var r = TranslateCore(entity, propertyName);
            
            return r ?? (string)Utilities.GetPropertyValue(entity, propertyName);
        }

        string TranslateCore(object entity, string propertyName)
        {
            var uniqueId = Utilities.GetUniqueId(entity);
            if (!_idToTranslation.ContainsKey(uniqueId)) return null;

            var columnName = Utilities.GetColumnName(entity.GetType(), propertyName);

            string result;
            if (!_idToTranslation[uniqueId].TryGetValue(columnName, out result)) return null;

            return result;
        }
    }

    class DefaultTranslation : ITranslation
    {
        public string Translate(object entity, string propertyName)
        {
            return (string)Utilities.GetPropertyValue(entity, propertyName);
        }
    }
}