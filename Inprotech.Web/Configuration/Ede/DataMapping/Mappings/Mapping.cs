using System.Collections.Generic;

namespace Inprotech.Web.Configuration.Ede.DataMapping.Mappings
{
    public class Mapping
    {
        public int? Id { get; set; }

        public string InputDesc { get; set; }

        public bool NotApplicable { get; set; }

        public virtual string OutputValueId
        {
            get { return null; }
        }
    }

    public class Mapping<T> : Mapping
    {
        public Output<T> Output { get; set; }

        public override string OutputValueId
        {
            get
            {
                if (Output == null || EqualityComparer<T>.Default.Equals(Output.Key, default(T)))
                    return null;

                return Output.Key.ToString();
            }
        }
    }

    public class Output<T>
    {
        public T Key { get; set; }

        public string Value { get; set; }
    }
}