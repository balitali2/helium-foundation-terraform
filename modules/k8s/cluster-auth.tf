resource "kubectl_manifest" "cluster-auth" {
  count      =  length(data.kubectl_path_documents.cluster-auth.documents)
  yaml_body  =  element(data.kubectl_path_documents.cluster-auth.documents, count.index)
}