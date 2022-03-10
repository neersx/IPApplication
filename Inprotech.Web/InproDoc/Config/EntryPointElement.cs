using System.Configuration;

namespace Inprotech.Web.InproDoc.Config
{
    public class EntryPointElement : ConfigurationElement
    {
        public EntryPointElement()
        {
        }

        public EntryPointElement(string name)
            : this()
        {
            Name = name;
        }

        [ConfigurationProperty("name", DefaultValue = "", IsRequired = true, IsKey = true)]
        public string Name
        {
            get => (string) this["name"];
            set => this["name"] = value;
        }

        [ConfigurationProperty("description", IsRequired = false)]
        public string Description
        {
            get => (string) this["description"];
            set => this["description"] = value;
        }

        [ConfigurationProperty("askLabel", IsRequired = false)]
        public string AskLabel
        {
            get => (string) this["askLabel"];
            set => this["askLabel"] = value;
        }

        [ConfigurationProperty("valueType", DefaultValue = EntryPointValueType.String, IsRequired = true)]
        public EntryPointValueType EntryPointValueType
        {
            get => (EntryPointValueType) this["valueType"];
            set => this["valueType"] = value;
        }

        [ConfigurationProperty("length", DefaultValue = null, IsRequired = false)]
        public int? Length
        {
            get => (int?) this["length"];
            set => this["length"] = value;
        }

        [ConfigurationProperty("require-validation", DefaultValue = true, IsRequired = false)]
        public bool RequireValidation
        {
            get => (bool) this["require-validation"];
            set => this["require-validation"] = value;
        }

        [ConfigurationProperty("item-validation", IsRequired = false)]
        public string ItemValidation
        {
            get => (string) this["item-validation"];
            set => this["item-validation"] = value;
        }

        [ConfigurationProperty("eval-item-on-register", IsRequired = false)]
        public bool EvalItemOnRegister
        {
            get => (bool) this["eval-item-on-register"];
            set => this["eval-item-on-register"] = value;
        }
    }
}