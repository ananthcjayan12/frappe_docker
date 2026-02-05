      - name: Trigger Coolify Redeploy (API)
        if: success()
        run: |
          echo "🚀 Triggering Coolify deployment..."
          curl --request GET \
            --url "${{ secrets.COOLIFY_URL }}/api/v1/deploy?uuid=${{ secrets.COOLIFY_RESOURCE_UUID }}&force=false" \
            --header "Authorization: Bearer ${{ secrets.COOLIFY_TOKEN }}"
          echo "✅ Deployment triggered!" 