using System.Configuration;

namespace Inprotech.Web.InproDoc.Config
{
    public class EntryPointsCollection : ConfigurationElementCollection
    {
        public override ConfigurationElementCollectionType CollectionType => ConfigurationElementCollectionType.AddRemoveClearMap;

        public new string AddElementName
        {
            get => base.AddElementName;
            set => base.AddElementName = value;
        }

        public new string ClearElementName
        {
            get => base.ClearElementName;
            set => base.AddElementName = value;
        }

        public new string RemoveElementName => base.RemoveElementName;

        public new int Count => base.Count;

        public EntryPointElement this[int index]
        {
            get => (EntryPointElement) BaseGet(index);
            set
            {
                if (BaseGet(index) != null)
                {
                    BaseRemoveAt(index);
                }

                BaseAdd(index, value);
            }
        }

        public new EntryPointElement this[string name] => (EntryPointElement) BaseGet(name);

        protected override ConfigurationElement CreateNewElement()
        {
            return new EntryPointElement();
        }

        protected override ConfigurationElement CreateNewElement(string elementName)
        {
            return new EntryPointElement(elementName);
        }

        protected override object GetElementKey(ConfigurationElement element)
        {
            return ((EntryPointElement) element).Name;
        }

        public int IndexOf(EntryPointElement contentType)
        {
            return BaseIndexOf(contentType);
        }

        public void Add(EntryPointElement contentType)
        {
            BaseAdd(contentType);
        }

        protected override void BaseAdd(ConfigurationElement element)
        {
            BaseAdd(element, false);
        }

        public void Remove(EntryPointElement contentType)
        {
            if (BaseIndexOf(contentType) >= 0)
            {
                BaseRemove(contentType.Name);
            }
        }

        public void RemoveAt(int index)
        {
            BaseRemoveAt(index);
        }

        public void Remove(string name)
        {
            BaseRemove(name);
        }

        public void Clear()
        {
            BaseClear();
        }
    }
}