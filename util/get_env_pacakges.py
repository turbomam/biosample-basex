from linkml_runtime.utils.schemaview import SchemaView

mixs_file = "../../mixs-source/model/schema/mixs.yaml"

mixs_view = SchemaView(mixs_file)

# classes that are is_a parents of other classes
# can't have any mxins
# also check some enum?

mixs_classes = mixs_view.all_classes()
mixs_class_names = [k for k, v in mixs_classes.items()]
mixs_class_names.sort()

mixs_class_parents = [v.is_a for k, v in mixs_classes.items()]

mixs_class_parents = list(set(mixs_class_parents))
mixs_class_parents = [i for i in mixs_class_parents if i]
mixs_class_parents.sort()

for i in mixs_class_parents:
    print(i)
